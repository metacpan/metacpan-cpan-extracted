# Test the adler32 implementation I stole from libxdiff.

use strict;
use warnings;
use Test::More;
use Algorithm::GDiffDelta qw( gdiff_adler32 );

# Skip all tests if we haven't got an implementation to compare against.
eval { require Digest::Adler32 };
if ($@) {
    plan skip_all => 'need Digest::Adler32 installed for this';
}
else {
    plan tests => 5;
}

is(gdiff_adler32(1, ''), 1, 'empty string leaves checksum unchanged');

test_adler('x');
test_adler('foo');
test_adler("\x00");
test_adler("\xFF");


# Test with the given string and compare against Digest::Adler32, and
# also test with the string repeated various numbers of times, both
# by generating one big string and by calling gdiff_adler32() repeatedly.
sub test_adler
{
    my ($s) = @_;
    my $digest = Digest::Adler32->new;
    my $adler = 1;

    for (1 .. 1024) {
        $digest->add($s);
        my $expected = unpack('N', $digest->clone->digest);

        $adler = gdiff_adler32($adler, $s);
        if ($adler != $expected || gdiff_adler32(1, $s x $_) != $expected) {
            fail('comparison against Digest::Adler32');
            return;
        }
    }

    pass('comparison against Digest::Adler32');
}

# vim:ft=perl ts=4 sw=4 expandtab:
