package Catmandu::Fix::marc_spec;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

our $VERSION = '1.251';

has spec          => ( fix_arg=> 1 );
has path          => ( fix_arg=> 1 );
has split         => ( fix_opt=> 1 );
has join          => ( fix_opt=> 1 );
has value         => ( fix_opt=> 1 );
has pluck         => ( fix_opt=> 1 );
has invert        => ( fix_opt=> 1 );
has nested_arrays => ( fix_opt=> 1 );

sub emit {
    my ( $self, $fixer ) = @_;
    my $path         = $fixer->split_path( $self->path );
    my $key          = $path->[-1];
    my $marc_obj     = Catmandu::MARC->instance;

    # Precompile the marc_path to gain some speed
    my $spec         = $marc_obj->parse_marc_spec( $self->spec );
    my $marc         = $fixer->capture($marc_obj);
    my $marc_spec    = $fixer->capture($spec);
    my $marc_opt     = $fixer->capture({
                            '-join'        => $self->join   // '' ,
                            '-split'       => $self->split  // 0 ,
                            '-pluck'       => $self->pluck  // 0 ,
                            '-nested_arrays' => $self->nested_arrays // 0 ,
                            '-invert'      => $self->invert // 0 ,
                            '-value'       => $self->value ,
                            '-force_array' => ($key =~ /^(\$.*|[0-9]+)$/) ? 1 : 0
                        });

    my $var          = $fixer->var;
    my $result       = $fixer->generate_var;
    my $current_value = $fixer->generate_var;

    my $perl = "";
    $perl .= $fixer->emit_declare_vars($current_value, "[]");
    $perl .=<<EOF;
if (defined(my ${result} = ${marc}->marc_spec(
            ${var},
            ${marc_spec},
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

__END__

=encoding utf-8

=head1 NAME

Catmandu::Fix::marc_spec - reference MARC values via
L<MARCspec - A common MARC record path language|http://marcspec.github.io/MARCspec/>

=head1 SYNOPSIS

In a fix file e.g. 'my.fix':

    # Assign value of MARC leader to my.ldr.all
    marc_spec('LDR', my.ldr.all)

    # Assign values of all subfields of field 245 as a joined string
    marc_spec('245', my.title.all)

    # If field 245 exists, set string 'the title' as the value of my.title.default
    marc_spec('245', my.title.default, value:'the title')

    # Assign values of all subfields of every field 650 to my.subjects.all
    # as a joined string
    marc_spec('650', my.subjects.all)

    # Same as above with joining characters '###'
    marc_spec('650', my.subjects.all, join:'###')

    # Same as above but added as an element to the array my.append.subjects
    marc_spec('650', my.append.subjects.$append, join:'###')

    # Every value of a subfield will be an array element
    marc_spec('650', my.split.subjects, split:1)

    # Assign values of all subfields of all fields having indicator 1 = 1
    # and indicator 2 = 0 to the my.fields.indicators10 array.
    marc_spec('...{^1=\1}{^2=\0}', my.fields.indicators10.$append)

    # Assign first four characters of leader to my.firstcharpos.ldr
    marc_spec('LDR/0-3', my.firstcharpos.ldr)

    # Assign last four characters of leader to my.lastcharpos.ldr
    marc_spec('LDR/#-3', my.lastcharpos.ldr)

    # Assign value of subfield a of field 245 to my.title.proper
    marc_spec('245$a', my.title.proper)

    # Assign first two characters of subfield a of field 245 to my.title.proper
    marc_spec('245$a/0-1', my.title.charpos)

    # Assign all subfields of second field 650 to my.second.subject
    marc_spec('650[1]', my.second.subject)

    # Assign values of all subfields of last field 650 to my.last.subject
    marc_spec('650[#]', my.last.subject)

    # Assign an array of values of all subfields of the first two fields 650
    # to my.two.split.subjects
    marc_spec('650[0-1]', my.two.split.subjects, split:1)

    # Assign a joined string of values of all subfields of the last two fields 650
    # to my.two.join.subjects
    marc_spec('650[#-1]', my.two.join.subjects, join:'###')

    # Assign value of first subfield a of all fields 020 to my.isbn.number
    marc_spec('020$a[0]', my.isbn.number)

    # Assign value of first subfield q of first field 020 to my.isbn.qual.one
    marc_spec('020[0]$q[0]', my.isbn.qual.none)

    # Assign values of subfield q and a in the order stated as an array
    # to  my.isbns.pluck.all
    # without option 'pluck:1' the elments will be in 'natural' order
    # see example below
    marc_spec('020$q$a', my.isbns.pluck.all, split:1, pluck:1)

    # Assign value of last subfield q and second subfield a
    # in 'natural' order of last field 020 as an array to my.isbn.qual.other
    marc_spec('020[#]$q[#]$a[1]', my.isbn.qual.other, split:1)

    # Assign first five characters of value of last subfield q and last character
    # of value of second subfield a in 'natural' order of all fields 020
    # as an array to  my.isbn.qual.substring.other
    marc_spec('020$q[#]/0-4$a[1]/#', my.isbn.qual.substring.other, split:1)

    # Assign values of of all other subfields than a of field 020
    # to my.isbn.other.subfields
    marc_spec('020$a', my.isbn.other.subfields, invert:1)

    # Assign value of subfield a of field 245 only, if subfield a of field 246
    # with value 1 for indicator1 exists
    marc_spec('245$a{246^1=\1}', my.var.title)

And then on command line:

    catmandu convert MARC to YAML --fix my.fix < perl_books.mrc

See L<Catmandu Importers|http://librecat.org/Catmandu/#importers> and
L<Catmandu Fixes|http://librecat.org/Catmandu/#fixes> for a deeper
understanding of how L<Catmandu|http://librecat.org/> works.

=head1 DESCRIPTION

L<Catmandu::Fix::marc_spec|Catmandu::Fix::marc_spec> is a fix for the
famous L<Catmandu Framework|Catmandu>.

For the most part it behaves like
L<Catmandu::Fix::marc_map|Catmandu::Fix::marc_map> , but has a more fine
grained method to reference MARC data content.

See L<MARCspec - A common MARC record path language|http://marcspec.github.io/MARCspec/>
for documentation on the path syntax.

=head1 METHODS

=head2 marc_spec(MARCspec, JSON_PATH, OPT:VAL, OPT2:VAL,...)

First parameter must be a string, following the syntax of
L<MARCspec - A common MARC record path language|http://marcspec.github.io/MARCspec/>.
Do always use single quotes with this first parameter.

Second parameter is a string describing the variable or the variable path
to assign referenced values to
(see L<Catmandu Paths|http://librecat.org/Catmandu/#paths>).

You may use one of $first, $last, $prepend or $append to add
referenced data values to a specific position of an array
(see L<Catmandu Wildcards|http://librecat.org/Catmandu/#wildcards> and
mapping rules at L<https://github.com/LibreCat/Catmandu-MARC/wiki/Mapping-rules>).

    # INPUT
    [245,1,0,"a","Cross-platform Perl /","c","Eric F. Johnson."]

    # CALL
    marc_spec('245', my.title.$append)

    # OUTPUT
    {
      my {
        title [
            [0] "Cross-platform Perl /Eric F. Johnson."
        ]
      }

    }

Third and every other parameters are optional and must
be in the form of key:value (see L</"OPTONS"> for a deeper
understanding of options).

=head1 OPTIONS

=head2 split: 0|1

If split is set to 1, every fixed fields value or every subfield will be
an array element.

    # INPUT
    [650," ",0,"a","Perl (Computer program language)"],
    [650," ",0,"a","Web servers."]

    # CALL
    marc_spec('650', my.subjects, split:1)

    # OUTPUT
    {
      my {
        subjects [
            [0] "Perl (Computer program language)",
            [1] "Web servers."
        ]
      }
    }

See split mapping rules at L<https://github.com/LibreCat/Catmandu-MARC/wiki/Mapping-rules>.


=head2 nested_arrays: 0|1

Using the nested_array
option the output will be an array of array of strings (one array item for
each matched field, one array of strings for each matched subfield).

    # INPUT
    [650," ",0,"a","Perl (Computer program language)"],
    [650," ",0,"a","Web servers."]

    # CALL
    marc_spec('650', my.subjects, nested_arrays:1)

    # OUTPUT
    {
      my {
        subjects [
            [0] [
                [0] "Perl (Computer program language)"
            ]
            [1] [
                [0] "Web servers."
            ]
        ]
      }
    }

See nested_array mapping rules at L<https://github.com/LibreCat/Catmandu-MARC/wiki/Mapping-rules>.

=head2 join: Str

If set, value of join will be used to join the referenced data content.
This will only have an effect if option split is undefined (not set or set to 0).

    # INPUT
    [650," ",0,"a","Perl (Computer program language)"],
    [650," ",0,"a","Web servers."]

    # CALL
    marc_spec('650', my.subjects, join:'###')

    # OUTPUT
    {
      my {
        subjects "Perl (Computer program language)###Web servers."
      }
    }

=head2 pluck: 0|1

This has only an effect on subfield values. By default subfield reference
happens in 'natural' order (first number 0 to 9 and then letters a to z).

    # INPUT
    ["020"," ", " ","a","0491001304","q","black leather"]

    # CALL
    marc_spec('020$q$a', my.isbn, split:1)

    # OUTPUT
    {
      my {
        isbn [
            [0] 0491001304,
            [1] "black leather"
        ]
      }
    }


If pluck is set to 1, values will be referenced by the order stated in the
MARCspec.

    # INPUT
    ["020"," ", " ","a","0491001304","q","black leather"]

    # CALL
    marc_spec('020$q$a', my.plucked.isbn, split:1, pluck:1)

    # OUTPUT
    {
      my {
        isbn [
            [0] "black leather",
            [1] 0491001304
        ]
      }
    }

=head2 value: Str

If set to a value, this value will be assigned to $var if MARCspec references
data content (if the field or subfield exists).

In case two or more subfields are referenced, the value will be assigned to $var if
at least one of them exists:

    # INPUT
    ["020"," ", " ","a","0491001304"]

    # CALL
    marc_spec('020$a$q', my.isbn, value:'one subfield exists')

    # OUTPUT
    {
      my {
        isbn "one subfield exists"
      }
    }

=head2 invert: 0|1

This has only an effect on subfields (values). If set to 1 it will invert the
last pattern for every subfield. E.g.

   # references all subfields but not subfield a and q
   marc_spec('020$a$q' my.other.subfields, invert:1)

   # references all subfields but not subfield a and not the last repetition
   # of subfield q
   marc_spec('020$a$q[#]' my.other.subfields, invert:1)

   # references all but not the last two characters of first subfield a
   marc_spec('020$a[0]/#-1' my.other.subfields, invert:1)

Invert will not work with subspecs.

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_spec as => 'marc_spec';

    my $data = { record => [...] };

    $data = marc_spec($data,'245$a','title');

    print $data->{title} , "\n";

=head1 SEE ALSO

L<Catmandu::Fix>
L<Catmandu::Fix::marc_map>

=head1 AUTHOR

Carsten Klee E<lt>klee@cpan.orgE<gt>

=head1 CONTRIBUTORS

=over

=item * Johann Rolschewski, C<< <jorol at cpan> >>,

=item * Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>,

=item * Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=back

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item * L<MARCspec - A common MARC record path language|http://marcspec.github.io/MARCspec/>

=item * L<Catmandu|http://librecat.org/>

=item * L<Catmandu Importers|http://librecat.org/Catmandu/#importers>

=item * L<Catmandu Importers|http://librecat.org/Catmandu/#importers>

=item * L<Catmandu Fixes|http://librecat.org/Catmandu/#fixes>

=item * L<Catmandu::MARC::Fix::marc_map|Catmandu::MARC::Fix::marc_map>

=item * L<Catmandu Paths|http://librecat.org/Catmandu/#paths>

=item * L<Catmandu Wildcards|http://librecat.org/Catmandu/#wildcards>

=item * L<MARC::Spec|MARC::Spec>

=item * L<Catmandu::Fix|Catmandu::Fix>

=item * L<Catmandu::MARC|Catmandu::MARC>

=back

=cut
