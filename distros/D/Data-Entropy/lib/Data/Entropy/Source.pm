=head1 NAME

Data::Entropy::Source - encapsulated source of entropy

=head1 SYNOPSIS

	use Data::Entropy::Source;

	$source = Data::Entropy::Source->new($handle, "sysread");

	$c = $source->get_octet;
	$str = $source->get_bits(17);
	$i = $source->get_int(12345);
	$i = $source->get_int(Math::BigInt->new("1000000000000"));
	$j = $source->get_prob(1, 2);

=head1 DESCRIPTION

An object of this class encapsulates a source of entropy
(randomness).  Methods allow entropy to be dispensed in any
quantity required, even fractional bits.  An entropy source object
should not normally be used directly.  Rather, it should be used to
support higher-level entropy-consuming algorithms, such as those in
L<Data::Entropy::Algorithms>.

This type of object is constructed as a layer over a raw entropy source
which does not supply methods to extract arbitrary amounts of entropy.
The raw entropy source is expected to dispense only entire octets at
a time.  The B</dev/random> devices on some versions of Unix constitute
such a source, for example.  The raw entropy source is accessed
via the C<IO::Handle> interface.  This interface may be supplied by
classes other than C<IO::Handle> itself, as is done for example by
C<Data::Entropy::RawSource::CryptCounter>.

If two entropy sources of this class are given exactly the same raw
entropy data, for example by reading from the same file, and exactly the
same sequence of C<get_> method calls is made to them, then they will
return exactly the same values from those calls.  (Calls with numerical
arguments that have the same numerical value but are of different
types count as the same for this purpose.)  This means that a run of an
entropy-using algorithm can be made completely deterministic if desired.

=cut

package Data::Entropy::Source;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);

our $VERSION = "0.007";

=head1 CONSTRUCTOR

=over

=item Data::Entropy::Source->new(RAW_SOURCE, READ_STYLE)

Constructs and returns an entropy source object based on the given raw
source.  RAW_SOURCE must be an I/O handle referring to a source of entropy
that can be read one octet at a time.  Specifically, it must support
either the C<getc> or C<sysread> method described in L<IO::Handle>.
READ_STYLE must be a string, either "getc" or "sysread", indicating which
method should be used to read from the raw source.  No methods other
than the one specified will ever be called on the raw source handle,
so a full implementation of C<IO::Handle> is not required.

The C<sysread> method should be used with B</dev/random> and its ilk,
because buffering would be very wasteful of entropy and might consequently
block other processes that require entropy.  C<getc> should be preferred
when reading entropy from a regular file, and it is the more convenient
interface to implement when a non-I/O object is being used for the handle.

=cut

sub new {
	my($class, $rawsrc, $readstyle) = @_;
	croak "no raw entropy source given" unless defined $rawsrc;
	croak "read style `$readstyle' not recognised"
		unless $readstyle =~ /\A(?:getc|sysread)\z/;
	return bless({
		rawsrc => $rawsrc,
		readstyle => $readstyle,
		limit => 1,
		num => 0,
	}, $class);
}

=back

=head1 METHODS

=over

=item $source->get_octet

Returns an octet of entropy, as a string of length one.  This provides
direct access to the raw entropy source.

=cut

sub get_octet {
	my($self) = @_;
	if($self->{readstyle} eq "getc") {
		my $errno = $!;
		$! = 0;
		my $octet = $self->{rawsrc}->getc;
		unless(defined $octet) {
			my $errmsg = $!;
			unless($errmsg) {
				$errmsg = "EOF";
				$! = $errno;
			}
			croak "entropy source failed: $errmsg";
		}
		$! = $errno;
		return $octet;
	} elsif($self->{readstyle} eq "sysread") {
		my $octet;
		my $n = $self->{rawsrc}->sysread($octet, 1);
		croak "entropy source failed: ".(defined($n) ? $! : "EOF")
			unless $n;
		return $octet;
	}
}

# ->_get_small_int may be used only with a native integer argument, up to 256.

sub _get_small_int {
	my($self, $limit) = @_;
	use integer;
	my $reqlimit = $limit << 15;
	while(1) {
		while($self->{limit} < $reqlimit) {
			$self->{num} = ($self->{num} << 8) +
					ord($self->get_octet);
			$self->{limit} <<= 8;
		}
		my $rep = $self->{limit} / $limit;
		my $uselimit = $rep * $limit;
		if($self->{num} < $uselimit) {
			my $num = $self->{num} / $rep;
			$self->{num} %= $rep;
			$self->{limit} = $rep;
			return $num;
		}
		$self->{num} -= $uselimit;
		$self->{limit} -= $uselimit;
	}
}

# ->_put_small_int is used to return the unused portion of some entropy that
# was extracted using ->_get_small_int.

sub _put_small_int {
	my($self, $limit, $num) = @_;
	$self->{limit} *= $limit;
	$self->{num} = $self->{num} * $limit + $num;
}

=item $source->get_bits(NBITS)

Returns NBITS bits of entropy, as a string of octets.  If NBITS is
not a multiple of eight then the last octet in the string has its most
significant bits set to zero.

=cut

sub get_bits {
	my($self, $nbits) = @_;
	my $nbytes = $nbits >> 3;
	$nbits &= 7;
	my $str = "";
	$str .= $self->get_octet while $nbytes--;
	$str .= chr($self->_get_small_int(1 << $nbits)) if $nbits;
	return $str;
}

=item $source->get_int(LIMIT)

LIMIT must be a positive integer.  Returns a uniformly-distributed
random number between zero inclusive and LIMIT exclusive.  LIMIT may be
either a native integer, a C<Math::BigInt> object, or an integer-valued
C<Math::BigRat> object; the returned number is of the same type.

This method dispenses a non-integer number of bits of entropy.
For example, if LIMIT is 10 then the result contains approximately 3.32
bits of entropy.  The minimum non-zero amount of entropy that can be
obtained is 1 bit, with LIMIT = 2.

=cut

sub _break_int {
	my($num) = @_;
	my $type = ref($num);
	$num = $num->as_number if $type eq "Math::BigRat";
	my @limbs;
	while($num != 0) {
		my $l = $num & 255;
		$l = $l->numify if $type ne "";
		push @limbs, $l;
		$num >>= 8;
	}
	return \@limbs;
}

sub get_int {
	my($self, $limit) = @_;
	my $type = ref($limit);
	my $max = _break_int($limit - 1);
	my $len = @$max;
	my @num_limbs;
	if($len) {
		TRY_AGAIN:
		my $i = $len;
		my $ml = $max->[--$i];
		my $nl = $self->_get_small_int($ml + 1);
		@num_limbs = ($nl);
		while($i && $nl == $ml) {
			$ml = $max->[--$i];
			$nl = $self->_get_small_int(256);
			if($nl > $ml) {
				$self->_put_small_int(255-$ml, $nl-$ml-1);
				goto TRY_AGAIN;
			}
			push @num_limbs, $nl;
		}
		push @num_limbs, ord($self->get_octet) while $i--;
	}
	my $num = $type eq "" ? 0 : Math::BigInt->new(0);
	for(my $i = $len; $i--; ) {
		my $l = $num_limbs[$len-1-$i];
		$l = Math::BigInt->new($l) if $type ne "";
		$num += $l << ($i << 3);
	}
	$num = Math::BigRat->new($num) if $type eq "Math::BigRat";
	return $num;
}

=item $source->get_prob(PROB0, PROB1)

PROB0 and PROB1 must be non-negative integers, not both zero.
They may each be either a native integer, a C<Math::BigInt> object,
or an integer-valued C<Math::BigRat> objects; types may be mixed.
Returns either 0 or 1, with relative probabilities PROB0 and PROB1.
That is, the probability of returning 0 is PROB0/(PROB0+PROB1), and the
probability of returning 1 is PROB1/(PROB0+PROB1).

This method dispenses a fraction of a bit of entropy.  The maximum
amount of entropy that can be obtained is 1 bit, with PROB0 = PROB1.
The more different the probabilities are the less entropy is obtained.
For example, if PROB0 = 1 and PROB1 = 2 then the result contains
approximately 0.918 bits of entropy.

=cut

sub get_prob {
	my($self, $prob0, $prob1) = @_;
	croak "probabilities must be non-negative"
		unless $prob0 >= 0 && $prob1 >= 0;
	if($prob0 == 0) {
		croak "can't have nothing possible" if $prob1 == 0;
		return 1;
	} elsif($prob1 == 0) {
		return 0;
	}
	my $max0 = _break_int($prob0 - 1);
	my $maxt = _break_int($prob0 + $prob1 - 1);
	my $len = @$maxt;
	push @$max0, (0) x ($len - @$max0) unless @$max0 == $len;
	TRY_AGAIN:
	my $maybe0 = 1;
	my $maybebad = 1;
	my($mtl, $m0l, $nl);
	for(my $i = $len - 1; ; $i--) {
		$nl = $self->_get_small_int(
			$i == $len-1 ? $maxt->[-1] + 1 : 256);
		$m0l = $maybe0 ? $max0->[$i] : -1;
		$mtl = $maybebad ? $maxt->[$i] : 256;
		my $lastlimb = $i ? 0 : 1;
		if($nl < $m0l + $lastlimb) {
			$self->_put_small_int($m0l + $lastlimb, $nl);
			return 0;
		} elsif($nl > $m0l && $nl < $mtl + $lastlimb) {
			$self->_put_small_int($mtl + $lastlimb - $m0l - 1,
						$nl - $m0l - 1);
			return 1;
		} elsif($nl > $mtl) {
			$self->_put_small_int(255 - $mtl, $nl - $mtl - 1);
			goto TRY_AGAIN;
		}
		$maybe0 = 0 if $nl > $m0l;
		$maybebad = 0 if $nl < $mtl;
	}
}

=back

=head1 SEE ALSO

L<Data::Entropy>,
L<Data::Entropy::Algorithms>,
L<Data::Entropy::RawSource::CryptCounter>,
L<Data::Entropy::RawSource::Local>,
L<Data::Entropy::RawSource::RandomOrg>,
L<IO::Handle>

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
