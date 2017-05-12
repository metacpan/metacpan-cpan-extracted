#!perl

use 5.006;
use Test::More;
use strict; use warnings;
use Calendar::Saka;
use File::Temp qw(tempfile tempdir);
use XML::SemanticDiff;

eval { Calendar::Saka->new({ year => -2011, month => 1 }); };
like($@, qr/ERROR: Invalid year \[\-2011\]./);

eval { Calendar::Saka->new({ year => 2011, month => 13 }); };
like($@, qr/ERROR: Invalid month \[13\]./);

my $got = Calendar::Saka->new->as_svg('Chaitra', 1937);
is(is_same_svg($got, 't/saka.xml'), 1, 'Saka Calendar');
is(is_same_svg($got, 't/fake-saka.xml'), 0, 'Fake Saka Calendar');
is(is_same_svg(Calendar::Saka->new->as_svg(1, 1937), 't/saka.xml'), 1, 'Saka Calendar');

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
