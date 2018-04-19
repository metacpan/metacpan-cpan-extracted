package Data::Cuid;

use strict;
use warnings;

our @EXPORT_OK;

BEGIN {
    use Exporter 'import';
    @EXPORT_OK = qw(cuid slug);
}

use List::Util 'reduce';
use Sys::Hostname 'hostname';
use Time::HiRes ();

our $size = 4;
our $base = 36;
our $cmax = ($base)**($size);

our $VERSION = "0.04";

{
    my $c = 0;

    sub _safe_counter {
        $c = $c < $cmax ? $c : 0;
        $c++;
    }
}

# from Math::Base36, but without using Math::BigInt (since only
# timestamp is the largest int used here )
sub _encode_base36 {
    my ( $n, $max ) = ( @_, 1 );

    my @res;
    while ($n) {
        my $remainder = $n % 36;
        unshift @res, $remainder <= 9 ? $remainder : chr( 55 + $remainder );
        $n = int $n / 36;
    }

    # also return this as a string of exactly $max characters; note
    # that this means numbers above 36**$max - 1 will be truncated to
    # $max size and be incorrect, unless $max is increased
    unshift @res, '0' while @res < $max;
    join '' => @res[ @res - $max .. $#res ];
}

# taken from the NodeJS version of fingerprint
# https://github.com/ericelliott/cuid/blob/master/lib/fingerprint.js
sub _fingerprint {
    my $padding = 2;
    my $pid = _encode_base36 $$, $padding;

    my $hostname = hostname;
    my $id = reduce { $a + ord($b) } length($hostname) + $base,
        split // => $hostname;

    join '' => $pid, _encode_base36 $id, $padding;
}

sub _random_block { _encode_base36 $cmax * rand() << 0, $size }

sub _timestamp {
    _encode_base36 sprintf( '%.0f' => Time::HiRes::time * 1000 ), 8;
}

sub cuid {
    lc join '' => 'c',
        _timestamp,
        _encode_base36( _safe_counter, $size ),
        _fingerprint,
        _random_block, _random_block;
}

sub slug {
    lc join '' => substr( _timestamp, -2 ),
        substr( _encode_base36(_safe_counter), -4 ),
        substr( _fingerprint, 0, 1 ), substr( _fingerprint, -1 ),
        substr( _random_block, -2 );
}

1;
__END__

=encoding utf-8

=for stopwords cuid cuids

=head1 NAME

Data::Cuid - collision-resistant IDs

=head1 SYNOPSIS

    use Data::Cuid qw(cuid slug);

    my $id   = cuid();          # cjg0i57uu0000ng9lwvds8vb3
    my $slug = slug();          # uv1nlmi

=head1 DESCRIPTION

C<Data::Cuid> is a port of the cuid JavaScript library for Perl.

Collision-resistant IDs (also known as I<cuids>) are optimized for
horizontal scaling and binary search lookup performance, especially for
web or mobile applications with a need to generate tens or hundreds of
new entities per second across multiple hosts.

C<Data::Cuid> does not export any functions by default.

=head1 FUNCTIONS

=head2 cuid

    my $cuid = cuid();

Produce a cuid as described in L<the original JavaScript
implementation|https://github.com/ericelliott/cuid#broken-down>.  This
cuid is safe to use as HTML element IDs, and unique server-side record
lookups.

=head2 slug

    my $slug = slug();

Produce a shorter ID in nearly the same fashion as L</cuid>.  This slug
is good for things like URL slug disambiguation (i.e., C<<
example.com/some-post-title-<slug> >>) but is absolutely not recommended
for database unique IDs.

=head1 SEE ALSO

L<Cuid|http://usecuid.org/>

=head1 LICENSE

The MIT License (MIT)

Copyright (C) Zak B. Elep.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Zak B. Elep E<lt>zakame@cpan.orgE<gt>

Original cuid JavaScript library maintained by L<Eric
Elliott|https://ericelliottjs.com>

=cut
