package Crypt::SHAVS;

use strict;
use vars qw($VERSION);

$VERSION   = 0.02;

sub new {
	my ($class, $SHA, $BIT) = @_;

	my $self = {};
	$self->{SHA} = $SHA;
	$self->{BIT} = $BIT;
	bless($self, $class);
}

sub _SHA {
	my $self = shift;

	pop unless $self->{BIT};
	&{$self->{SHA}}(@_);
}

sub _computeMsg {
	my ($self, $values) = @_;

	my $Msg2bin = pack("H*", $values->{Msg});
	my $nbits  = $values->{Len};
	my $nbytes = $nbits >> 3;
	if ($nbits % 8) { $nbytes++ }
	$Msg2bin = substr($Msg2bin, 0, $nbytes)
			if $nbytes < length($Msg2bin);

	unpack("H*", $self->_SHA($Msg2bin, $nbits));
}

sub _computeMonte {
	my ($self, $values) = @_;

	die "COUNT value out of sequence: $values->{COUNT}\n"
		if $values->{count}++ != $values->{COUNT};
	my ($MD0, $MD1, $MD2, $MDi) = (pack("H*", $values->{Seed})) x 3;
	for (1..1000) {
		my $M = $MD0 . $MD1 . $MD2;
		$MDi = $self->_SHA($M, length($M)*8);
		($MD0, $MD1, $MD2) = ($MD1, $MD2, $MDi);
	}
	$values->{Seed} = unpack("H*", $MDi);
}

my $TAGS = join('|', qw(Len Msg MD Seed COUNT));

sub check {
	my ($self, $file) = @_;

	local $_;
	local *F;
	open(F, $file) or die $!;

	my $values = { 'count' => 0 };
	while (<F>) {
		next unless /^\s*($TAGS)\s*=\s*([\da-f]+)/o;
		$values->{$1} = $2;
		next unless $1 eq 'MD';
		my $computed = defined $values->{Msg}
			? $self->_computeMsg($values)
			: $self->_computeMonte($values);
		my $ok = $computed eq $values->{MD};
		print "$computed ", $ok ? "OK" : "FAILED", "\n";
	}
	close(F);
}

1;
__END__

=head1 NAME

Crypt::SHAVS - Interface to NIST SHA Validation System

=head1 SYNOPSIS

	# Check SHA-256 implementation in Digest::SHA (BYTE mode):

	use Crypt::SHAVS;
	use Digest::SHA qw(sha256);

	$shavs = Crypt::SHAVS->new(\&sha256);
	for $file (glob('SHA256*.rsp')) {
		$shavs->check($file);
	}

=head1 ABSTRACT

Crypt::SHAVS automates the checking of any SHA implementation by comparing
its behavior against the detailed test vectors of NIST's SHA Validation
System (SHAVS).  The capability extends to the testing of upcoming SHA-3
implementations as well, assuming the continued use of SHAVS by NIST.

=head1 DESCRIPTION

Crypt::SHAVS is designed for ease of use rather than power.  The user
doesn't need to understand the details of SHAVS test vectors or the
algorithms used in processing short, long, and pseudorandomly-generated
test messages.

Rather, as the SYNOPSIS illustrates, the user simply passes a reference
to the SHA function under test, and indicates which test vectors are to
be examined.  Crypt::SHAVS reports the value computed by the function
for each vector, and whether that value matches (OK) or doesn't match
(FAILED) the expected result.

Most SHA implementations are BYTE oriented, meaning that they allow
input data only in units of whole bytes.  Crypt::SHAVS has the ability
to handle BIT implementations as well.  To use the latter, simply pass
a second argument to the constructor with a true value, and supply
a reference to a 2-argument function that calls the appropriate BIT
implementation.  Here's how it's done with Perl's Digest::SHA module,
this time using SHA-1:

	use Crypt::SHAVS;
	use Digest::SHA;

	$sha1BIT = sub {Digest::SHA->new()->add_bits($_[0], $_[1])->digest};

	$shavs = Crypt::SHAVS->new($sha1BIT, 1);
	for $file (glob('SHA1*.rsp')) {
		$shavs->check($file);
	}

Note that in this case, the I<rsp> files must be taken from NIST's
repository of SHA bit-oriented messages (ref. L<SEE ALSO>), whereas in
the SYNOPSIS they're taken from among the byte-oriented messages.

=head1 OBJECT-ORIENTED INTERFACE

In keeping with the theme of simplicity, the Crypt::SHAVS object supplies
only two methods:

=over 4

=item B<new($sha, $BIT)>

Returns a new Crypt::SHAVS object.  The first argument, I<$sha>, is a
reference to the SHA function being tested.  The optional second argument
is set only for testing BIT-oriented messages.

In the more usual case of BYTE-oriented messages, the I<$sha> function
being referenced takes a single argument consisting of the B<binary>
message whose B<binary> digest is to be calculated.  The I<$sha> function
is allowed to accept more than one argument, like the various sha...()
functions of Digest::SHA and Digest::SHA1, but no more than one argument
is ever supplied internally by Crypt::SHAVS for byte-oriented messages.

For BIT-oriented messages, the I<$sha> function takes a second argument
designating the number of bits in the message.  The above example
illustrates the appropriate construction of a bit-oriented function
for Digest::SHA.

=item B<check($file)>

This method accepts the name of a particular file from either of the
two NIST test vector repositories (ref. L<SEE ALSO>).  Those file names
adhere to the following pattern:

	$file = "SHA" . $alg . $type . ".rsp"

where I<$alg> can take values from I<(1, 224, 256, 384, 512)>, and
I<$type> is selected from I<qw(ShortMsg LongMsg Monte)>.

For each vector, I<check()> will print the value computed by the I<$sha>
function passed previously to I<new()>, and then compare that value
to the expected value and print "OK" if the values match, and "FAILED"
if they don't.

=back

=head1 EXPORT

None

=head1 EXPORTABLE FUNCTIONS

None

=head1 SEE ALSO

L<Digest>, L<Digest::SHA>, L<Digest::SHA1>, L<Digest::SHA::PurePerl>

NIST SHAVS - Test Vectors for Bit-Oriented and Byte-Oriented Messages:

L<http://csrc.nist.gov/groups/STM/cavp/index.html#03>

The Secure Hash Standard (Draft FIPS PUB 180-3):

L<http://csrc.nist.gov/publications/fips/fips180-3/fips180-3_final.pdf>

=head1 AUTHOR

	Mark Shelor	<mshelor@cpan.org>

=head1 ACKNOWLEDGMENTS

The author is grateful to

	Gisle Aas

for ideas and suggestions beneficial to the construction of this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Mark Shelor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

L<perlartistic>

=cut
