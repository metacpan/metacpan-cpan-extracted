package Catmandu::Fix::marc_copy;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

our $VERSION = '1.13';

has marc_path      => (fix_arg => 1);
has path           => (fix_arg => 1);
has equals         => (fix_opt => 1);

sub emit {
    my ($self,$fixer) = @_;
    my $path         = $fixer->split_path($self->path);
    my $key          = $path->[-1];
    my $marc_obj     = Catmandu::MARC->instance;

    # Precompile the marc_path to gain some speed
    my $marc_context = $marc_obj->compile_marc_path($self->marc_path, subfield_wildcard => 0);
    my $marc         = $fixer->capture($marc_obj);
    my $marc_path    = $fixer->capture($marc_context);
    my $equals       = $fixer->capture($self->equals);

    my $var           = $fixer->var;
    my $result        = $fixer->generate_var;
    my $current_value = $fixer->generate_var;

    my $perl = "";
    $perl .= $fixer->emit_declare_vars($current_value, "[]");
    $perl .=<<EOF;
if (my ${result} = ${marc}->marc_copy(
            ${var},
            ${marc_path},
            ${equals}) ) {
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

=head1 NAME

Catmandu::Fix::marc_copy - copy marc data in a structured way to a new field

=head1 SYNOPSIS

    # fixed field
    marc_copy(001, fixed001)

    Can result in:

    fixed001 : [
        {
            "tag": "001",
            "ind1": null,
            "ind2": null,
            "content": "fol05882032 "
        }
    ]

    And

    # variable field
    marc_copy(650, subjects)

    Can result in:

    subjects:[
        {
            "subfields" : [
                {
                    "a" : "Perl (Computer program language)"
                }
            ],
            "ind1" : " ",
            "ind2" : "0",
            "tag" : "650"
      },
      {
            "ind1" : " ",
            "subfields" : [
                {
                    "a" : "Web servers."
                }
            ],
            "tag" : "650",
            "ind2" : "0"
      }
    ]


=head1 DESCRIPTION

Copy MARC data referred by MARC_TAG in a structured way to JSON path.

In contrast to L<Catmandu::Fix::marc_map> and L<Catmandu::Fix::marc_spec>
marc_copy will not only copy data content (values) but also all data elements
like tag, indicators and subfield codes into a nested data structure.

=head1 METHODS

=head2 marc_copy(MARC_PATH, JSON_PATH, [equals: REGEX])

Copy this MARC fields referred by a MARC_PATH to a JSON_PATH.

When the MARC_PATH points to a MARC tag then only the fields mathching the MARC
tag will be copied. When the MATCH_PATH contains indicators or subfields, then
only the MARC_FIELDS which contain data in these subfields will be copied. Optional,
a C<equals> regular expression can be provided that should match the subfields that
need to be copied:

    # Copy all the 300 fields
    marc_copy(300,tmp)

    # Copy all the 300 fields with indicator 1 = 1
    marc_copy(300[1],tmp)

    # Copy all the 300 fields which have subfield c
    marc_copy(300c,tmp)

    # Copy all the 300 fields which have subfield c equal to 'ABC'
    marc_copy(300c,tmp,equal:"^ABC")

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_copy as => 'marc_copy';

    my $data = { record => ['650', ' ', 0, 'a', 'Perl'] };

    $data = marc_copy($data,'650','subject');

    print $data->{subject}->[0]->{tag} , "\n"; # '650'
    print $data->{subject}->[0]->{ind1} , "\n"; # ' '
    print $data->{subject}->[0]->{ind2} , "\n"; # 0
    print $data->{subject}->[0]->{subfields}->[0]->{a} , "\n"; # 'Perl'

=head1 SEE ALSO

=over

=item * L<Catmandu::Fix::marc_cut>

=item * L<Catmandu::Fix::marc_paste>

=back

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
