package Catmandu::Fix::marc_cut;

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
            ${equals},1) ) {
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

Catmandu::Fix::marc_cut - cut marc data in a structured way to a new field

=head1 SYNOPSIS

    # Cut the 001 field out of the MARC record into the fixed001
    marc_cut(001, fixed001)

    # Cut all 650 fields out of the MARC record into the subjects array
    marc_cut(650, subjects)

=head1 DESCRIPTION

This Fix work like L<Catmandu::Fix::marc_copy> except it will also remove all
mathincg fields from the MARC record

=head1 METHODS

=head2 marc_cut(MARC_PATH, JSON_PATH, [equals: REGEX])

Cut this MARC fields referred by a MARC_PATH to a JSON_PATH.

When the MARC_PATH points to a MARC tag then only the fields mathching the MARC
tag will be copied. When the MATCH_PATH contains indicators or subfields, then
only the MARC_FIELDS which contain data in these subfields will be copied. Optional,
a C<equals> regular expression can be provided that should match the subfields that
need to be copied:

    # Cut all the 300 fields
    marc_cut(300,tmp)

    # Cut all the 300 fields with indicator 1 = 1
    marc_cut(300[1],tmp)

    # Cut all the 300 fields which have subfield c
    marc_cut(300c,tmp)

    # Cut all the 300 fields which have subfield c equal to 'ABC'
    marc_cut(300c,tmp,equal:"^ABC")

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_copy as => 'marc_cut';

    my $data = { record => ['650', ' ', 0, 'a', 'Perl'] };

    $data = marc_cut($data,'650','subject');

    print $data->{subject}->[0]->{tag} , "\n"; # '650'
    print $data->{subject}->[0]->{ind1} , "\n"; # ' '
    print $data->{subject}->[0]->{ind2} , "\n"; # 0
    print $data->{subject}->[0]->{subfields}->[0]->{a} , "\n"; # 'Perl'

=head1 SEE ALSO

=over

=item * L<Catmandu::Fix::marc_copy>

=item * L<Catmandu::Fix::marc_paste>

=back

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
