#!/usr/bin/perl

use 5.006;
use Test::More;
use strict; use warnings;
use Calendar::Gregorian;
use File::Temp qw(tempfile tempdir);
use XML::SemanticDiff;

eval { Calendar::Gregorian->new({ year => -1390, month => 1 }); };
like($@, qr/ERROR: Invalid year \[\-1390\]./);

eval { Calendar::Gregorian->new({ year => 1390, month => 13 }); };
like($@, qr/ERROR: Invalid month \[13\]./);

my $got = Calendar::Gregorian->new->as_svg('May', 2016);
is(is_same_svg($got, 't/gregorian.xml'), 1, 'Gregorian Calendar');
is(is_same_svg($got, 't/fake-gregorian.xml'), 0, 'Fake Gregorian Calendar');
is(is_same_svg(Calendar::Gregorian->new->as_svg(5, 2016), 't/gregorian.xml'), 1, 'Gregorian Calendar');

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
