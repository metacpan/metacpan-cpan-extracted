package Crypt::DRBG::HMAC;
$Crypt::DRBG::HMAC::VERSION = '0.001000';
use 5.006;
use strict;
use warnings;

use parent 'Crypt::DRBG';

use Digest::SHA ();

=head1 NAME

Crypt::DRBG::HMAC - Fast, cryptographically secure PRNG

=head1 SYNOPSIS

	use Crypt::DRBG::HMAC;

	my $drbg = Crypt::DRBG::HMAC->new(auto => 1);
	my $data = $drbg->generate(42);
	... # do something with your 42 bytes here

	my $drbg2 = Crypt::DRBG::HMAC->new(seed => "my very secret seed");
	my $data2 = $drbg->generate(42);

=head1 DESCRIPTION

Crypt::DRBG::HMAC is an implementation of the HMAC_DRBG from NIST SP800-90A.  It
is a fast, cryptographically secure PRNG.  By default, it uses HMAC-SHA-512.

However, if provided a seed, it will produce the same sequence of bytes I<if
called the same way each time>.  This makes it useful for simulations that
require good but repeatable random numbers.

Note, however, that due to the way the DRBGs are designed, making a single
request and making multiple requests for the same number of bytes will result in
different data.  For example, two 16-byte requests will not produce the same
values as one 32-byte request.

This class derives from Crypt::DRBG, which provides several utility functions.

=head1 SUBROUTINES/METHODS

=head2 Crypt::DRBG::HMAC->new(%params)

Creates a new Crypt::DRBG::HMAC.

%params can contain all valid values for Crypt::DRBG::initialize, plus the
following.

=over 4

=item algo

The algorithm to use for generating bytes.  The default is "512", for
HMAC-SHA-512.  This provides optimal performance for 64-bit machines.

If Perl (and hence Digest::SHA) was built with a compiler lacking 64-bit integer
support, use "256" here.  "256" may also provide better performance for 32-bit
machines.

=item func

If you would like to use a different hash function, you can specify a function
implemeting HMAC for your specific algorithm.  The function should take two
arguments, the value and the key, in that order.

For example, if you had C<Digest::BLAKE2> and C<Digest::HMAC> installed, you
could do the following to use BLAKE2b:

	my $func = sub {
		return Digest::HMAC::hmac(@_, \&Digest::BLAKEx::blake2b, 128);
	};
	my $drbg = Crypt::DRBG::HMAC->new(auto => 1, func => $func;
	my $data = $drbg->generate(42);

Note that the algo parameter is still required, explicitly or implicitly, in
order to know how large a seed to use.

=back

=cut

sub new {
	my ($class, %params) = @_;

	$class = ref($class) || $class;
	my $self = bless {}, $class;

	my $algo = $self->{algo} = $params{algo} || '512';
	$algo =~ tr{/}{}d;
	$self->{s_func} = ($params{func} || Digest::SHA->can("hmac_sha$algo")) or
		die "Unsupported algorithm '$algo'";
	$self->{seedlen} = $algo =~ /^(384|512)$/ ? 111 : 55;
	$self->{reseed_interval} = 4294967295; # (2^32)-1
	$self->{bytes_per_request} = 2 ** 16;
	$self->{outlen} = substr($algo, -3) / 8;
	$self->{security_strength} = $self->{outlen} / 2;
	$self->{min_length} = $self->{security_strength};
	$self->{max_length} = 4294967295; # (2^32)-1

	$self->initialize(%params);

	return $self;
}

sub _seed {
	my ($self, $seed) = @_;

	my $k = "\x00" x $self->{outlen};
	my $v = "\x01" x $self->{outlen};
	$self->{state} = {k => $k, v => $v};
	return $self->_reseed($seed);
}

sub _reseed {
	my ($self, $seed) = @_;

	$self->_update($seed);
	$self->{reseed_counter} = 1;
	return 1;
}

sub _update {
	my ($self, $seed) = @_;

	my $data = defined $seed ? $seed : '';

	my $func = $self->{s_func};
	my $state = $self->{state};
	my ($k, $v) = @{$state}{qw/k v/};
	$k = $func->("$v\x00$data", $k);
	$v = $func->($v, $k);
	if (defined $seed) {
		$k = $func->("$v\x01$data", $k);
		$v = $func->($v, $k);
	}
	@{$state}{qw/k v/} = ($k, $v);
	return 1;
}

=head2 $drbg->generate($bytes, $additional_data)

Generate and return $bytes bytes.  $bytes cannot exceed 2^16.

If $additional_data is specified, add this additional data to the DRBG.

=cut

sub _generate {
	my ($self, $len, $seed) = @_;

	$self->_check_reseed($len);
	$self->_update($seed) if defined $seed;

	my $count = ($len + ($self->{outlen} - 1)) / $self->{outlen};
	my $data = '';
	my $state = $self->{state};
	my ($k, $v) = @{$state}{qw/k v/};
	my $func = $self->{s_func};
	for (1..$count) {
		$v = $func->($v, $k);
		$data .= $v;
	}
	$self->{reseed_counter}++;
	@{$state}{qw/k v/} = ($k, $v);
	$self->_update($seed);
	return substr($data, 0, $len);
}

=head1 AUTHOR

brian m. carlson, C<< <sandals at crustytoothpaste.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-drbg at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-DRBG>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Crypt::DRBG::HMAC


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-DRBG>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-DRBG>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-DRBG>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-DRBG/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 brian m. carlson.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Crypt::DRBG::HMAC
