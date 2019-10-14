package Catmandu::Fix::marc_map;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

our $VERSION = '1.253';

has marc_path      => (fix_arg => 1);
has path           => (fix_arg => 1);
has split          => (fix_opt => 1);
has join           => (fix_opt => 1);
has value          => (fix_opt => 1);
has pluck          => (fix_opt => 1);
has nested_arrays  => (fix_opt => 1);

sub emit {
    my ($self,$fixer) = @_;
    my $path         = $fixer->split_path($self->path);
    my $key          = $path->[-1];
    my $marc_obj     = Catmandu::MARC->instance;

    # Precompile the marc_path to gain some speed
    my $marc_context = $marc_obj->compile_marc_path($self->marc_path,subfield_wildcard => 1);
    my $marc         = $fixer->capture($marc_obj);
    my $marc_path    = $fixer->capture($marc_context);
    my $marc_opt     = $fixer->capture({
                            '-join'          => $self->join   // '' ,
                            '-split'         => $self->split  // 0 ,
                            '-pluck'         => $self->pluck  // 0 ,
                            '-nested_arrays' => $self->nested_arrays // 0 ,
                            '-value'         => $self->value ,
                            '-force_array'   => ($key =~ /^(\$.*|[0-9]+)$/) ? 1 : 0
                        });

    my $var           = $fixer->var;
    my $result        = $fixer->generate_var;
    my $current_value = $fixer->generate_var;

    my $perl = "";
    $perl .= $fixer->emit_declare_vars($current_value, "[]");
    $perl .=<<EOF;
if (defined(my ${result} = ${marc}->marc_map(
            ${var},
            ${marc_path},
            ${marc_opt})) ) {
    ${result} = ref(${result}) ? ${result} : [${result}];
    for ${current_value} (\@{${result}}) {
EOF

    $perl .= $fixer->emit_create_path(
            $var,
            $path,
            sub {
                my $var2 = shift;
                "${var2} = ${current_value}"
            }
    );

    $perl .=<<EOF;
    }
}
EOF
    $perl;
}

1;

=head1 NAME

Catmandu::Fix::marc_map - copy marc values of one field to a new field

=head1 SYNOPSIS

    # Append all 245 subfields to my.title field the values are joined into one string
    marc_map('245','my.title')

    # Append al 245 subfields to the my.title keeping all subfields as an array
    marc_map('245','my.title', split:1)

    # Copy the 245-$a$b$c subfields into the my.title hash in the order provided in the record
    marc_map('245abc','my.title')

    # Copy the 245-$c$b$a subfields into the my.title hash in the order c,b,a
    marc_map('245cba','my.title', pluck:1)

    # Add the 100 subfields into the my.authors array
    marc_map('100','my.authors.$append')

    # Add the 710 subfields into the my.authors array
    marc_map('710','my.authors.$append')

    # Add the 600-$x subfields into the my.subjects array while packing each into a genre.text hash
    marc_map('600x','my.subjects.$append.genre.text')

    # Copy the 008 characters 35-37 into the my.language hash
    marc_map('008/35-37','my.language')

    # Copy all the 600 fields into a my.stringy hash joining them by '; '
    marc_map('600','my.stringy', join:'; ')

    # When 024 field exists create the my.has024 hash with value 'found'
    marc_map('024','my.has024', value:found)

    # When 260c field exists create the my.has260c hash with value 'found'
    marc_map('260c','my.has260c', value:found)

    # Copy all 100 subfields except the digits to the 'author' field
    marc_map('100^0-9','author')

    # Map all the 500 - 599 fields to my.notes
    marc_map('5..','my.motes')

    # Map the 100-a field where indicator-1 is 3
    marc_map('100[3]a','name.family')

    # Map the 245-a field where indicator-2 is 0
    marc_map('245[,0]a','title')

    # Map the 245-a field where indicator-1 is 1 and indicator-2 is 0
    marc_map('245[1,0]a','title')

=head1 DESCRIPTION

Copy data from a MARC field to JSON path.

This module implements a small subset of the L<MARCspec|http://marcspec.github.io/MARCspec/>
specification to map MARC fields. For a more extensive MARC path implementation
please take a look at Casten Klee's MARCSpec module: L<Catmandu::Fix::marc_spec>

=head1 METHODS

=head2 marc_map(MARC_PATH, JSON_PATH, OPT:VAL, OPT2:VAL,...)

Copy the value(s) of the data found at a MARC_PATH to a JSON_PATH.

The MARC_PATH can point to a MARC field. For instance:

    marc_map('245',title)
    marc_map('020',isbn)

The MARC_PATH can point to one or more MARC subfields. For instamce:

    marc_map('245a',title)
    marc_map('245ac',title)

You can also use dollar signs to indicate subfields

    marc_map('245$a$c',title)

Wildcards are allowed in the field names:

    # Map all the 200-fields to a title
    marc_map('2..'',title)

To filter out specific fields indicators can be used:

    # Only map the MARC fields with indicator-1 is '1' to title
    marc_map('245[1,]',title)

Also a substring of a field value can be mapped:

    # Map 008 position 35 to 37 to the language field
    marc_map('008/35-37',language)

By default all matched fields in a MARC_PATH will be joined into one string.
This behavior can be changed using one more more options (see below).

Visit our Wiki L<https://github.com/LibreCat/Catmandu-MARC/wiki/Mapping-rules>
for a complete overview of all allowed mappings.

=head1 OPTIONS

=head2 split: 0|1

When split is set to 1 then all mapped values will be joined into an array
instead of a string.

    # The subject field will contain an array of strings (one string
    # for each 500 field found)
    marc_map('500',subject, split: 1)

    # The subject field will contain a string
    marc_map('500', subject)

=head2 join: Str

By default all the values are joined into a string without a field separator.
Use the join function to set the separator.

    # All subfields of the 245 field will be separated with a space " "
    marc_map('245',title, join: " ")

=head2 pluck: 0|1

Be default, all subfields are added to the mapping in the order they are found
in the record. Using the pluck option, one can select the required order of
subfields to map.

    # First write the subfield-c to the title, then the subfield_a
    marc_map('245ca',title, pluck:1)

=head2 value: Str

Don't write the value of the MARC (sub)field to the JSON_PATH but the specified
string value.

    # has_024_a will contain the value 'Y' if the MARC field 024 subfield-a
    # exists
    marc_map('024a',has_024_a,value:Y)

=head2 nested_arrays: 0|1

When the split option is specified the output of the mapping will always be an
array of strings (one string for each subfield found). Using the nested_array
option the output will be an array of array of strings (one array item for
each matched field, one array of strings for each matched subfield).

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_map as => 'marc_map';

    my $data = { record => [...] };

    $data = marc_map($data,'245a','title');

    print $data->{title} , "\n";

=head1 SEE ALSO

L<Catmandu::Fix>
L<Catmandu::Fix::marc_spec>

=cut
