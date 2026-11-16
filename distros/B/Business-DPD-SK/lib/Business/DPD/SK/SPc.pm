package Business::DPD::SK::SPc;

use warnings;
use strict;

our $VERSION = '0.01';

use File::Spec;
use Sys::Path; # remove after install

sub _path_types {qw(
    prefix
    localstatedir
    sysconfdir
    sharedstatedir
)};

sub prefix        { Sys::Path->find_distribution_root(__PACKAGE__) };
sub localstatedir { File::Spec->catdir(__PACKAGE__->prefix, 'var') };

sub sysconfdir     { File::Spec->catdir(__PACKAGE__->prefix, 'etc') };
sub sharedstatedir { File::Spec->catdir(__PACKAGE__->localstatedir, 'lib') };

1;

__END__

=head1 NAME

Business::DPD::SK::SPc - system paths of the Business-DPD-SK distribution

=head1 SYNOPSIS

    use Business::DPD::SK::SPc;
    my $etc = Business::DPD::SK::SPc->sysconfdir;
    my $lib = Business::DPD::SK::SPc->sharedstatedir;

=head1 DESCRIPTION

In a source checkout these methods return directories inside the checkout.
C<./Build install> (L<Module::Build::SysPath>) replaces them with the system
directories of the installing perl, for example F</etc> and F</var/lib>.

=head1 METHODS

=head2 sysconfdir

Directory containing F<dpd-sk/geordb.ini>.

=head2 sharedstatedir

Directory containing F<dpd-sk/>, where GeoRDB zip files are stored.

=head2 prefix

=head2 localstatedir

Base directories the other paths derive from in a checkout.

=cut
