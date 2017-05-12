package Crypt::DRBG::Hash;
$Crypt::DRBG::Hash::VERSION = '0.000002';
use 5.006;
use strict;
use warnings;

use parent 'Crypt::DRBG';

use Digest::SHA ();

=head1 NAME

Crypt::DRBG::Hash - Fast, cryptographically secure PRNG

=head1 SYNOPSIS

    use Crypt::DRBG::Hash;

    my $drbg = Crypt::DRBG::Hash->new(auto => 1);
	my $data = $drbg->generate(42);
    ... # do something with your 42 bytes here

	my $drbg2 = Crypt::DRBG::Hash->new(seed => "my very secret seed");
	my $data2 = $drbg->generate(42);

=head1 DESCRIPTION

Crypt::DRBG::Hash is an implementation of the Hash_DRBG from NIST SP800-90A.  It
is a fast, cryptographically secure PRNG.  By default, it uses SHA-512.

However, if provided a seed, it will produce the same sequence of bytes I<if
called the same way each time>.  This makes it useful for simulations that
require good but repeatable random numbers.

Note, however, that due to the way the DRBGs are designed, making a single
request and making multiple requests for the same number of bytes will result in
different data.  For example, two 16-byte requests will not produce the same
values as one 32-byte request.

This class derives from Crypt::DRBG, which provides several utility functions.

=head1 SUBROUTINES/METHODS

=head2 Crypt::DRBG::Hash->new(%params)

Creates a new Crypt::DRBG::Hash.

%params can contain all valid values for Crypt::DRBG::initialize, plus the
following.

=over 4

=item algo

The algorithm to use for generating bytes.  The default is "512", for
SHA-512.  This provides optimal performance for 64-bit machines.

If Perl (and hence Digest::SHA) was built with a compiler lacking 64-bit integer
support, use "256" here.  "256" may also provide better performance for 32-bit
machines.

=back

=cut

sub new {
	my ($class, %params) = @_;

	$class = ref($class) || $class;
	my $self = bless {}, $class;

	my $algo = $self->{algo} = $params{algo} || '512';
	$algo =~ tr{/}{}d;
	$self->{s_func} = Digest::SHA->can("sha$algo") or
		die "Unsupported algorithm '$algo'";
	$self->{seedlen} = $algo =~ /^(384|512)$/ ? 111 : 55;
	$self->{reseed_interval} = 4294967295; # (2^32)-1
	$self->{bytes_per_request} = 2 ** 16;
	$self->{outlen} = substr($algo, -3) / 8;
	$self->{security_strength} = $self->{outlen} / 2;
	$self->{min_length} = $self->{security_strength};
	$self->{max_length} = 4294967295; # (2^32)-1

	# If we have a 64-bit Perl, make things much faster.
	my $is_64 = (4294967295 + 2) != 1;
	if ($is_64) {
		$self->{s_add} = \&_add_64;
	}
	else {
		require Math::BigInt;
		eval { Math::BigInt->import(try => 'GMP') };

		$self->{s_mask} =
			(Math::BigInt->bone << ($self->{seedlen} * 8)) - 1;
		$self->{s_add} = \&_add_32;
	}

	$self->initialize(%params);

	return $self;
}

sub _add {
	my ($self, @args) = @_;
	my $func = $self->{s_add};
	return $self->$func(@args);
}

sub _derive {
	my ($self, $hashdata, $len) = @_;

	my $count = ($len + ($self->{outlen} - 1)) / $self->{outlen};
	my $data = '';
	my $func = $self->{s_func};
	for (1..$count) {
		$data .= $func->(pack('CN', $_, $len * 8) . $hashdata);
	}
	return substr($data, 0, $len);
}

sub _seed {
	my ($self, $seed) = @_;

	my $v = $self->_derive($seed, $self->{seedlen});
	my $c = $self->_derive("\x00$v", $self->{seedlen});
	$self->{state} = {c => $c, v => $v};
	$self->{reseed_counter} = 1;
	return 1;
}

sub _reseed {
	my ($self, $seed) = @_;

	return $self->_seed("\x01$self->{state}{v}$seed");
}

sub _add_32 {
	my ($self, @args) = @_;
	my @items = map { Math::BigInt->new("0x" . unpack("H*", $_)) } @args;
	my $final = Math::BigInt->bzero;
	foreach my $val (@items) {
		$final += $val;
	}
	$final &= $self->{s_mask};
	my $data = substr($final->as_hex, 2);
	$data = "0$data" if length($data) & 1;
	$data = pack("H*", $data);
	return ("\x00" x ($self->{seedlen} - length($data))) . $data;
}

sub _add_64 {
	my ($self, $x, @args) = @_;

	use integer;

	my $nbytes = $self->{seedlen} + 1;
	my $nu32s = $nbytes / 4;
	# Optimize based on the fact that the first argument is always full-length.
	my @result = unpack('V*', reverse "\x00$x");
	my @vals = map {
		[unpack('V*', reverse(("\x00" x ($nbytes - length($_))) .  $_))]
	} @args;

	foreach my $i (0..($nu32s-1)) {
		my $total = $result[$i];
		foreach my $val (@vals) {
			$total += $val->[$i];
		}
		if ($total > 0xffffffff) {
			$result[$i+1] += $total >> 32;
		}
		$result[$i] = $total;
	}
	return substr(reverse(pack("V*", @result)), 1);
}

sub _hashgen {
	my ($self, $v, $len) = @_;

	my $func = $self->{s_func};
	my $count = int(($len + ($self->{outlen} - 1)) / $self->{outlen});
	my $data = '';
	for (1..$count) {
		$data .= $func->($v);
		$v = $self->_add($v, "\x01");
	}
	return substr($data, 0, $len);
}

=head2 $drbg->generate($bytes, $additional_data)

Generate and return $bytes bytes.  $bytes cannot exceed 2^16.

If $additional_data is specified, add this additional data to the DRBG.

=cut

sub _generate {
	my ($self, $len, $seed) = @_;

	$self->_check_reseed($len);

	my ($func, $add) = @{$self}{qw/s_func s_add/};
	my ($c, $v) = @{$self->{state}}{qw/c v/};
	if (defined $seed) {
		my $w = $func->("\x02$v$seed");
		$v = $self->$add($v, $w);
	}
	my $data = $self->_hashgen($v, $len);
	my $h = $func->("\x03$v");
	$v = $self->$add($v, $h, $c, pack("N*", $self->{reseed_counter}));
	$self->{reseed_counter}++;
	$self->{state}{v} =  $v;
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

    perldoc Crypt::DRBG::Hash


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

1; # End of Crypt::DRBG::Hash
