#!perl

use 5.006;
use Test::More;
use strict; use warnings;
use Calendar::Hijri;
use File::Temp qw(tempfile tempdir);
use XML::SemanticDiff;

eval { Calendar::Hijri->new({ year => -1432, month => 1 }); };
like($@, qr/ERROR: Invalid year \[\-1432\]./);

eval { Calendar::Hijri->new({ year => 1432, month => 13 }); };
like($@, qr/ERROR: Invalid month \[13\]./);

my $got = Calendar::Hijri->new->as_svg('Rajab', 1437);
is(is_same_svg($got, 't/hijri.xml'), 1, 'Hijri Calendar');
is(is_same_svg($got, 't/fake-hijri.xml'), 0, 'Fake Hijri Calendar');
is(is_same_svg(Calendar::Hijri->new->as_svg(7, 1437), 't/hijri.xml'), 1, 'Hijri Calendar');

done_testing();

# PRIVATE METHOD

sub is_same_svg {
    my ($got, $expected) = @_;

    my $dir = tempdir(CLEANUP => 1);
    my ($fh, $filename) = tempfile(DIR => $dir);
    print $fh $got;
    close $fh;

    my $xml = XML::SemanticDiff->new;
    my @changes = $xml->compare($filename, $expected);
    return (scalar(@changes))?(0):(1);
}
