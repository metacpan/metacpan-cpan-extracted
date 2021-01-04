#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 1e-3;

BEGIN {
	use_ok( 'Astro::Montenbruck::Ephemeris', qw/:all/ );
    use_ok( 'Astro::Montenbruck::Ephemeris::Planet', qw/:ids/ );
}

my $jd;
my $data;
my @ids;

BEGIN {
    my $path = "$Bin/19650201.txt";
    open(my $TEST, '<', $path) or die "Could not open $path: $!\n";

    while(<$TEST>) {
        chomp;
        my @flds = split /\s+/;
        next unless @flds;

        if ($flds[0] eq 'JD') {
            $jd = $flds[1]
        }
        else {
            push @ids, $flds[0];
            $data->{$flds[0]} = [ @flds[1..3] ]
        }
    }
    close $TEST;
}

subtest 'Planets' => sub {
    plan tests => 2;
    my $t  = ($jd - 2451545) / 36525;

    subtest 'Iterator interface' => sub {
        plan tests => (scalar @ids) * 3;
        my $iter = iterator($t, \@ids);
        while ( my $res = $iter->() ) {
            my ($id, $pos) = @$res;
            my ($x0, $y0, $z0) = @{ $data->{$id} };
            my ($x1, $y1, $z1) = @$pos;

            delta_ok($x0, $x1, "$id X") or diag("Expected: $x0, got: $x1");
            delta_ok($y0, $y1, "$id Y") or diag("Expected: $y0, got: $y1");
            delta_ok($z0, $z1, "$id Z") or diag("Expected: $z0, got: $z1");
        }
    };

    subtest 'Callback interface' => sub {
        plan tests => (scalar @ids) * 3;

        find_positions($t, \@ids, sub {
            my $id = shift;
            my @pos = @_;
            my ($x0, $y0, $z0) = @{ $data->{$id} };

            delta_ok($x0, $pos[0], "$id X") or diag("Expected: $x0, got: $pos[0]");
            delta_ok($y0, $pos[1], "$id Y") or diag("Expected: $y0, got: $pos[1]");
            delta_ok($z0, $pos[2], "$id Z") or diag("Expected: $z0, got: $pos[2]");
        });
    };
};

subtest 'Pluto' => sub {
    plan tests => 4;

    is(iterator(-1.10000002101935, [$PL])->(), undef, '1889-12-30 23:59')
        or diag('Expected undefined result for years < 1890');

    is(iterator(1.00000001901285, [$PL])->(), undef, '2100-01-01 12:01')
        or diag('Expected undefined result for years > 2099');

    ok(iterator(-1.09999998299365, [$PL])->(), '1889-12-31 00:01')
        or diag('Expected defined result for years > 1889');

    ok(iterator(0.999999980987148, [$PL])->(), '2100-01-01 11:59')
        or diag('Expected defined result for years < 2101');
};

done_testing();
