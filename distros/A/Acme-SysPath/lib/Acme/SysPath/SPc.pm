package Acme::SysPath::SPc;

=head1 NAME

Acme::SysPath::SPc - build-time system path configuration

=cut

use warnings;
use strict;

our $VERSION = '0.05';

use File::Spec;

sub _path_types {qw(
	sysconfdir
	datadir
)};

=head1 PATHS

=head2 prefix

=head2 sysconfdir

=head2 datadir

=cut

sub prefix     { use Sys::Path; Sys::Path->find_distribution_root(__PACKAGE__); };
sub sysconfdir { File::Spec->catdir(__PACKAGE__->prefix, 'conf') };
sub datadir    { File::Spec->catdir(__PACKAGE__->prefix, 'share') };

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
