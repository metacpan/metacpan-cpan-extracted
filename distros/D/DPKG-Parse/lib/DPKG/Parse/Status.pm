=head1 NAME

DPKG::Parse::Status - Parse the "status" file

=head1 SYNOPSIS

    use DPKG::Parse::Status;

    my $status = DPKG::Parse::Status->new;
    while (my $entry = $status->next_package) {
        print $entry->package . " " . $entry->version . "\n";
    }

    my $postfix = $status->get_package('name' => 'postfix');

    my $postfix = $status->get_installed('name' => 'postfix');

=head1 DESCRIPTION

L<DPKG::Parse::Status> parses a dpkg "status" file and turns
each entry into a L<DPKG::Parse::Entry> object.  By default, it uses
the Debian default location of "/var/lib/dpkg/status".

See L<DPKG::Parse> for more information on the get_package and next_package
methods.

See L<DPKG::Parse::Entry> for more information on the entry objects.

=head1 METHODS

=over 4

=cut

package DPKG::Parse::Status;

our $VERSION = '0.03';

use DPKG::Parse::Entry;
use Params::Validate qw(:all);
use Class::C3;
use base qw(DPKG::Parse);
use strict;
use warnings;

DPKG::Parse::Status->mk_accessors(qw(installed));

=item new('filename' => '/var/lib/dpkg/status')

Creates a new DPKG::Parse::Status object.  By default, it tries to open
/var/lib/dpkg/status.

=cut
sub new {
    my $pkg = shift;
    my %p = validate(@_,
        {
            'filename' => { 'type' => SCALAR, 'default' => '/var/lib/dpkg/status', 'optional' => 1 },
            'debug' => { 'type' => SCALAR, 'default' => 0, 'optional' => 1 }
        }
    );
    my $ref = $pkg->next::method('filename' => $p{'filename'}, debug => $p{debug});
    return $ref;
}

=item parse

Calls DPKG::Parse::parse, and populates the "installed" accessor with a hash
of packages whose "status" is "install ok installed".

=cut
sub parse {
    my $pkg = shift;
    $pkg->next::method;
    my $installed;
    foreach my $entry (@{$pkg->entryarray}) {
        if ($entry->status =~ /^install ok installed$/) {
           $installed->{$entry->package} = $entry;
        }
    }
    $pkg->installed($installed);
}

=item get_installed('name' => 'postfix');

Returns a L<DPKG::Parse::Entry> object for the given package, or undef if
it's not found.

=cut
sub get_installed {
    my $pkg = shift;
    my %p = validate( @_,
        {
            'name' => { 'type' => SCALAR, },
        },
    );
    return $pkg->get_package('name' => $p{'name'}, 'hash' => 'installed');
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

