package Alien::Win32::LZMA;

=pod

=head1 NAME

Alien::Win32::LZMA - Install and make available lzma.exe

=head1 DESCRIPTION

On Windows (unlike on Unix systems) the primary mechanism for accessing
LZMA functionality is via the 7-Zip desktop application.

B<Alien::Win32::LZMA> is a simple Alien module which embeds a copy
of the F<lzma.exe> command line utility for use in situations where
the memory-only compression and decompression provided by the current
generation of modules is not sufficient.

The version of lzma.exe provided by this module is taken from the LZMA
SDK 4.65 at L<http://downloads.sourceforge.net/sevenzip/lzma465.tar.bz2>.

=head1 FUNCTIONS

=cut

use 5.008;
use strict;
use warnings;
use Carp                ();
use Exporter            ();
use IPC::Run3     0.042 ();
use File::ShareDir 1.00 ();

our $VERSION = '4.66';
our @ISA     = 'Exporter';

=pod

=head2 lzma_exe

The C<lzma_exe> function returns the location of the installed
F<lzma.exe> command line application as a string.

=cut

sub lzma_exe {
	File::ShareDir::dist_file('Alien-Win32-LZMA', 'lzma.exe');
}

=pod

=head2 lzma_version

The C<lzma_version> function runs F<lzma.exe> and finds the version
of the application. It should match the version of this module.

=cut

sub lzma_version {
	my $exe    = lzma_exe();
	my $stderr = '';
	my $result = IPC::Run3::run3(
		[ $exe ],
		\undef,
		\undef,
		\$stderr,
	);
	unless ( $result ) {
		die "$exe execution failed";
	}
	unless  ( $stderr =~ /^\s*LZMA\s*([\d\.]+)/s ) {
		die "Failed to find LZMA version";
	}
	return "$1";
}

=pod

=head2 lzma_compress

  lzma_compress('file', 'file.lz') or die('Failed to compress');

The C<lzma_compress> function invokes F<lzma.exe> to compress one file
into another file.

Any additional params to C<lzma_compress> will be passed through to
the underlying command line call as options.

Returns true if the invocation returns without error.

=cut

sub lzma_compress {
	my $from = shift;
	my $to   = shift;
	my $cmd  = lzma_exe();
	unless ( -f $from ) {
		Carp::croak("No such file or directory '$from'");
	}
	IPC::Run3::run3(
		[ $cmd, 'e', $from, $to, @_ ],
		\undef, \undef, \undef,
	);
}

=pod

=head2 lzma_decompress

  lzma_decompress('file','file.lz') or die('Failed to decompress');

The C<lzma_decompress> function invokes F<lzma.exe> to decompress
an LZMA file into another file.

Any additional params to C<lzma_compress> will be passed through to
the underlying command line call as options.

Returns true if the invocation returns without error.

=cut

sub lzma_decompress {
	my $from = shift;
	my $to   = shift;
	my $cmd  = lzma_exe();
	unless ( -f $from ) {
		Carp::croak("No such file or directory '$from'");
	}
	IPC::Run3::run3(
		[ $cmd, 'd', $from, $to, @_ ],
		\undef, \undef, \undef,
	);
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-Win32-LZMA>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Compress::umLZMA>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

The LZMA SDK is written and placed in the public domain by
Igor Pavlov.

=cut
