#!/usr/bin/perl

use 5.006;
use Test::More;
use strict; use warnings;
use Calendar::Persian;
use File::Temp qw(tempfile tempdir);
use XML::SemanticDiff;

eval { Calendar::Persian->new({ year => -1390, month => 1 }); };
like($@, qr/ERROR: Invalid year \[\-1390\]./);

eval { Calendar::Persian->new({ year => 1390, month => 13 }); };
like($@, qr/ERROR: Invalid month \[13\]./);

my $got = Calendar::Persian->new->as_svg('Ordibehesht', 1395);
is(is_same_svg($got, 't/persian.xml'), 1, 'Persian Calendar');
is(is_same_svg($got, 't/fake-persian.xml'), 0, 'Fake Persian Calendar');
is(is_same_svg(Calendar::Persian->new->as_svg(2, 1395), 't/persian.xml'), 1, 'Persian Calendar');

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
