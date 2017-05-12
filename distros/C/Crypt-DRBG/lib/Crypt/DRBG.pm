package Crypt::DRBG;
$Crypt::DRBG::VERSION = '0.000002';
use 5.006;
use strict;
use warnings;

use IO::File ();

=head1 NAME

Crypt::DRBG - Base class for fast, cryptographically-secure PRNGs

=head1 SYNOPSIS

    use Crypt::DRBG::HMAC;

    my $drbg = Crypt::DRBG::HMAC->new(auto => 1);
	my $data = $drbg->generate(42);
    ... # do something with your 42 bytes here

	my $drbg2 = Crypt::DRBG::HMAC->new(seed => "my very secret seed");
	my @randdigits = $drbg->randitems(20, [0..9]);
	... # do something with your 20 random digits here

=head1 SUBROUTINES/METHODS

=head2 initialize(%params)

%params can contain the following:

=over 4

=item auto

If true, use a safe, cryptographically-secure set of defaults.
Equivalent to specifying autoseed, autononce, autopersonalize, and
fork_safe.

=item autoseed

If true, derive a seed from /dev/urandom, /dev/arandom, or /dev/random, in that
order.  Windows support is lacking, but may be added in the future; however,
this should function on Cygwin.

=item seed

If a string, use this value as the seed.  If a coderef, call this coderef with a
single argument (the number of bytes) to obtain an entropy input.  Note that if
a string is used, an exception will be thrown if a reseed is required.

=item autononce

If true, derive a nonce automatically.

=item nonce

If a string, use this value as the nonce.  If a coderef, call this coderef with
a single argument (the number of bytes) to obtain a nonce.

=item autopersonalize

If true, derive a personalization string automatically.

=item personalize

If a string, use this value as the personalization string.  If a coderef, call
this coderef to obtain a personalization string.

=item fork_safe

If true, reseed on fork.  If false, the parent and child processes will produce
the same sequence of bytes (not recommended).

=item cache

If enabled, keep a cache of this many bytes and use it to satisfy requests
before generating more.

=back

=cut

# Not a method call.
sub _rand_bytes {
	my ($len) = @_;

	my $data = '';
	my @sources = qw{/dev/urandom /dev/arandom /dev/random};
	foreach my $source (@sources) {
		my $fh = IO::File->new($source, 'r') or next;
		while ($fh->read(my $buf, $len - length($data))) {
			$data .= $buf;
		}
		die "Insufficient random data" if length($data) != $len;
		return $data;
	}
	die "No random source for autoseed";
}

sub _get_seed {
	my ($self, $name, $len, $params, $optional) = @_;
	my $autoname = "auto$name";

	my $seed;
	if (defined $params->{$name} && !ref $params->{$name}) {
		$seed = $params->{$name};
	}
	else {
		my $seedfunc;
		$seedfunc = $params->{$name} if ref $params->{$name} eq 'CODE';
		$seedfunc = \&_rand_bytes if $params->{$autoname} || $params->{auto};
		unless ($seedfunc) {
			die "No seed source" unless $optional;
			return '';
		}
		$self->{"${name}func"} = $seedfunc;
		$seed = $seedfunc->($len);
	}

	return $seed;
}

sub _get_personalization {
	my ($self, $params) = @_;
	my $name = 'personalize';
	my $autoname = "auto$name";

	my $seed;
	if (defined $params->{$name} && !ref $params->{$name}) {
		$seed = $params->{$name};
	}
	else {
		my $seedfunc;
		$seedfunc = $params->{$name} if ref $params->{$name} eq 'CODE';
		if ($params->{$autoname} || $params->{auto}) {
			die "Invalid version"
				if defined $params->{version} && $params->{version};
			my $version = 0;
			$seedfunc = sub {
				my @nums = ($$, $<, $>, time);
				my @strings = ($0, $(, $));

				return join('',
					"$version\0",
					pack("N" x @nums, @nums),
					pack("Z" x @strings, @strings),
				);
			};
		}
		# Personalization strings are recommended, but optional.
		return '' unless $seedfunc;
		$seed = $seedfunc->();
	}

	return $seed;
}

sub _check_reseed {
	my ($self) = @_;

	my $reseed = 0;
	my $pid = $self->{pid};
	$reseed = 1 if defined $pid && $pid != $$;
	$reseed = 1 if $self->{reseed_counter} >= $self->{reseed_interval};

	if ($reseed) {
		die "No seed source" if !$self->{seedfunc};
		$self->_reseed($self->{seedfunc}->($self->{seedlen}));
		$self->{pid} = $$ if $self->{fork_safe};
	}

	return 1;
}

sub initialize {
	my ($self, %params) = @_;

	my $seed = $self->_get_seed('seed', $self->{seedlen}, \%params);
	my $nonce = $self->_get_seed('nonce', int(($self->{seedlen} / 2) + 1),
		\%params, 1);
	my $personal = $self->_get_personalization(\%params);

	$self->_seed("$seed$nonce$personal");

	if ($params{cache}) {
		$self->{cache} = '';
		$self->{cache_size} = $params{cache};
	}

	$self->{fork_safe} = $params{fork_safe};
	$self->{fork_safe} = 1 if $params{auto} && !defined $params{fork_safe};
	$self->{pid} = $$ if $self->{fork_safe};

	return 1;
}

=head2 $drbg->generate($bytes, $additional_data)

Generate and return $bytes bytes.  There is a limit per algorithm on the number of bytes that can be requested at once, which is at least 2^10.

If $additional_data is specified, add this additional data to the DRBG.

If the cache flag was specified on instantiation, bytes will be satisfied from
the cache first, unless $additional_data was specified.

=cut

sub generate {
	my ($self, $len, $seed) = @_;

	return $self->_generate($len, $seed)
		if !defined $self->{cache} || defined $seed;

	my $data = '';
	my $left = $len;
	my $cache = \$self->{cache};
	$$cache = $self->_generate($self->{cache_size}) if !length($$cache);
	while ($left > 0) {
		my $chunk_size = $left > length($$cache) ? length($$cache) : $left;
		$data .= substr($$cache, 0, $chunk_size, '');
		$left = $len - length($data);
		$$cache = $self->_generate($self->{cache_size}) if !length($$cache);
	}

	return $data;
}

=head2 $drbg->rand([$n], [$num])

Like Perl's rand, but cryptographically secure.  Uses 32-bit values.

Accepts an additional argument, $num, which is the number of values to return.
Defaults to 1 (obviously).

Note that just as with Perl's rand, there may be a slight bias with this
function.  Use randitems if that matters to you.

Returns an array if $num is specified and a single item if it is not.

=cut

sub rand {
	my ($self, $n, $num) = @_;

	my $single = !defined $num;

	$n = 1 unless defined $n;
	$num = 1 unless defined $num;

	my $bytes = $self->generate($num * 4);
	my @data = map { $_ / 2.0 / (2 ** 31) * $n } unpack("N[$num]", $bytes);
	return $single ? $data[0] : @data;
}

=head2 $drbg->randitems($n, $items)

Select randomly and uniformly from the arrayref $items $n times.

=cut

sub randitems {
	my ($self, $n, $items) = @_;

	my $len = scalar @$items;
	my @results;
	my $values = [
		{bytes => 1, pack => 'C', max => 256},
		{bytes => 2, pack => 'n', max => 65536},
		{bytes => 4, pack => 'N', max => 2 ** 31},
	];
	my $params = $values->[$len <= 256 ? 0 : $len <= 65536 ? 1 : 2];

	# Getting this computation right is important so as not to bias the
	# data.  $len & $len - 1 is true iff $len is not a power of two.
	my $max = $params->{max};
	my $mask = $max - 1;
	if ($len & ($len - 1)) {
		$max = $max - ($max % $len);
	}
	else {
		$mask = $len - 1;
	}

	my $pack = "$params->{pack}\[$n\]";
	while (@results < $n) {
		my $bytes = $self->generate($params->{bytes} * $n);

		my @data = map { $_ & $mask } grep { $_ < $max } unpack($pack, $bytes);
		push @results, map { $items->[$_ % $len] } @data;
	}

	return splice(@results, 0, $n);
}

=head2 $drbg->randbytes($n, $items)

Select randomly and uniformly from the characters in arrayref $items $n times.
Returns a byte string.

This function works just like randitems, but is more efficient if generating a
sequence of bytes as a string instead of an array.

=cut

sub randbytes {
	my ($self, $n, $items) = @_;

	my $len = scalar @$items;
	my $results = '';

	# Getting this computation right is important so as not to bias the
	# data.  $len & $len - 1 is true iff $len is not a power of two.
	my $max = 256;
	my $filter = sub { return $_[0]; };
	if ($len & ($len - 1)) {
		$max = $max - ($max % $len);
		my $esc = sprintf '\x%02x', $max + 1;
		$filter = sub {
			my $s = shift;
			eval "\$s =~ tr/$esc-\\xff//d";  ## no critic(ProhibitStringyEval)
			return $s;
		};
	}

	while (length $results < $n) {
		my $bytes = $filter->($self->generate($n));
		$results .= join '', map { $items->[$_ % $len] } unpack('C*', $bytes);
	}

	return substr($results, 0, $n);
}

=head1 AUTHOR

brian m. carlson, C<< <sandals at crustytoothpaste.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-drbg at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-DRBG>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::DRBG


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

1; # End of Crypt::DRBG
