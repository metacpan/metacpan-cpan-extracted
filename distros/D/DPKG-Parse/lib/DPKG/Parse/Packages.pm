=head1 NAME

DPKG::Parse::Packages - Parse the Packages file

=head1 SYNOPSIS

    use DPKG::Parse::Packages;

    my $packages = DPKG::Parse::Packages->new(
        'filename' => '/usr/src/packages/Packages',
    );
    while (my $entry = $packages->next_package) {
        print $entry->package . " " . $entry->version . "\n";
    }

    my $postfix = $packages->get_package('name' => 'postfix');

=head1 DESCRIPTION

L<DPKG::Parse::Packages> parses a dpkg/apt style Packages file and turns
each entry into a L<DPKG::Parse::Entry> object.

See L<DPKG::Parse> for more information on the get_package and next_package
methods.

See L<DPKG::Parse::Entry> for more information on the entry objects.

=head1 METHODS

=over 4

=cut

package DPKG::Parse::Packages;

our $VERSION = '0.03';

use Params::Validate qw(:all);
use Class::C3;
use base qw(DPKG::Parse);
use strict;
use warnings;

=item new('filename' => '/usr/src/packages/Packages')

Creates a new DPKG::Parse::Packages object.  By default, it tries to open
/usr/src/packages/Packages.

=cut
sub new {
    my $pkg = shift;
    my %p = validate(@_,
        {
            'filename' => { 'type' => SCALAR, 'default' => '/usr/src/packages/Packages', 'optional' => 1 },
        }
    );
    my $ref = $pkg->next::method('filename' => $p{'filename'});
    return $ref;
}

1;

__END__
=back

=head1 SEE ALSO

L<DPKG::Parse>, L<DPKG::Parse::Entry>

=head1 AUTHOR

Adam Jacob, C<holoway@cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as perl itself.

=cut
