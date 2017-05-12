#!/usr/bin/perl

use 5.006;
use Test::More;
use strict; use warnings;
use Calendar::Bahai;
use File::Temp qw(tempfile tempdir);
use XML::SemanticDiff;

eval { Calendar::Bahai->new({ year => -168, month => 1 }); };
like($@, qr/ERROR: Invalid year \[\-168\]./);

eval { Calendar::Bahai->new({ year => 168, month => 24 }); };
like($@, qr/ERROR: Invalid month \[24\]./);

my $got = Calendar::Bahai->new->as_svg('Baha', 172);
is(is_same_svg($got, 't/bahai.xml'), 1, 'Bahai Calendar');
is(is_same_svg($got, 't/fake-bahai.xml'), 0, 'Fake Bahai Calendar');
is(is_same_svg(Calendar::Bahai->new->as_svg(1, 172), 't/bahai.xml'), 1, 'Bahai Calendar');

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
