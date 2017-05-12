=head1 NAME

Data::Entropy::RawSource::Local - read randomness from local device

=head1 SYNOPSIS

	use Data::Entropy::RawSource::Local;

	my $rawsrc = Data::Entropy::RawSource::Local->new;

	$rawsrc->sysread($c, 1);
	# and the rest of the I/O handle interface

=head1 DESCRIPTION

This class provides a constructor to open an I/O handle connected to
a local source of random octets.  This may be a strong entropy source,
depending on the OS, but not every OS has such a facility at all.

There are no actual objects blessed into this class.  Only the constructor
belongs to this class; it returns C<IO::File> objects.  For use as
a general entropy source, it is recommended to wrap the handle using
C<Data::Entropy::Source>, which provides methods to extract entropy in
more convenient forms than mere octets.

On systems with a blocking B</dev/random>, such as Linux, the bits
generated can be totally unbiased and uncorrelated.  Such an entropy
stream is suitable for all uses, including security applications.
However, the rate of entropy generation is limited, so applications
requiring a large amount of apparently-random data might prefer to fake
it cryptographically (see L<Data::Entropy::RawSource::CryptCounter>).

On systems where B</dev/random> does not block, the bits generated are
necessarily correlated to some extent, but it should be cryptographically
difficult to detect the correlation.  Such an entropy source is not
suitable for all applications.  Some other systems lack B</dev/random>
entirely.  If satisfactory entropy cannot be generated locally, consider
downloading it from a server (see L<Data::Entropy::RawSource::RandomOrg>
and L<Data::Entropy::RawSource::RandomnumbersInfo>).

=cut

package Data::Entropy::RawSource::Local;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use IO::File 1.03;

our $VERSION = "0.007";

=head1 CONSTRUCTOR

=over

=item Data::Entropy::RawSource::Local->new([FILENAME])

Opens a file handle referring to the randomness device, or C<die>s
on error.  The device opened is B</dev/random> by default, but this may
be overridden by giving a FILENAME argument.

The default device name may in the future be different on different OSes,
if their equivalent devices are in different places.

=cut

sub new {
	my($class, $filename) = @_;
	$filename = "/dev/random" unless defined $filename;
	my $self = IO::File->new($filename, "r");
	croak "can't open $filename: $!" unless defined $self;
	return $self;
}

=back

=head1 METHODS

There are no actual objects blessed into this class.  The constuctor
returns C<IO::File> objects.  See L<IO::File> for the interface.  It is
recommended to use unbuffered reads (the C<sysread> method) rather than
buffered reads (the C<getc> method et al), to avoid wasting entropy that
could be used by another process.

=head1 SEE ALSO

L<Data::Entropy::RawSource::CryptCounter>,
L<Data::Entropy::RawSource::RandomOrg>,
L<Data::Entropy::RawSource::RandomnumbersInfo>,
L<Data::Entropy::Source>,
L<IO::File>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2009, 2011
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
