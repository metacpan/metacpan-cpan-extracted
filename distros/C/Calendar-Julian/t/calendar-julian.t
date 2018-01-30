#!perl

use 5.006;
use Test::More;
use strict; use warnings;
use Calendar::Julian;
use File::Temp qw(tempfile tempdir);
use XML::SemanticDiff;

eval { Calendar::Julian->new({ year => -2018, month => 1 }); };
like($@, qr/ERROR: Invalid year \[\-2018\]./);

eval { Calendar::Julian->new({ year => 2018, month => 13 }); };
like($@, qr/ERROR: Invalid month \[13\]./);

my $got = Calendar::Julian->new->as_svg('January', 2018);
is(is_same_svg($got, 't/julian.xml'), 1, 'Julian Calendar');
is(is_same_svg($got, 't/fake-julian.xml'), 0, 'Fake Julian Calendar');
is(is_same_svg(Calendar::Julian->new->as_svg(1, 2018), 't/julian.xml'), 1, 'Julian Calendar');

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
