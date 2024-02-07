package Digest::MD5;

use strict;
use warnings;

use Exporter;
use XSLoader;

our $VERSION = 0.03;
our @EXPORT_OK = qw(md5 md5_hex md5_base64);

*import = \&Exporter::import;

our @ISA;
eval {
	require Digest::base;
	@ISA = qw/Digest::base/;
};
if ($@) {
	my $err = $@;
	*add_bits = sub { die $err };
}

XSLoader::load('Digest::MD5', $VERSION);
*reset = \&new;

1;

=head1 NAME

Digest::MD5 - Perl interface to the MD5 Algorithm

=cut
