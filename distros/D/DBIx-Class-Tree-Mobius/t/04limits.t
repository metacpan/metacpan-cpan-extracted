#! /usr/bin/perl -w

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

use bigint;

use Test::More;

use File::Spec;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');

my @limits = (
    # limit with int & float (SQLite)
    { int => 4294967295, depth => 7, max_index => 13, tests => 94 },
    # limit with bigint & double (MySQL)
    # { int => 18446744073709551615, depth => 5, max_index => 7129, tests => 128}, => ok
    # { int => 18446744073709551615, depth => 21, max_index => 6, tests => 128},
    );

plan tests => $limits[0]->{tests};

#1
use_ok("CdbiTreeTest");

my $schema = CdbiTreeTest->init_schema;
my $rs     = $schema->resultset('Test');

use Math::Matrix;

foreach my $test (@limits) {
    
    $rs->delete_all();

    my $m = new Math::Matrix ([$test->{max_index} + 2,1],[1,0]);
    my $x;

    my $rightmost_node;
    my $rightmost_path='';
    foreach my $level (1..$test->{depth}) {
        $x = defined $x ? $x->multiply($m) : $m->clone;
        
        foreach my $index (1..$test->{max_index}) {

            my $node;
            if ($level == 1) {
                $node = $rs->create({ data => "level $level / node $index" });
            } else {
                $node = $rs->create({ parent => $rightmost_node->id, data => "level $level / node $index" });
            }
            my $child = $rs->create({ parent => $node->id, data => "child of ($level/$index)" });
            $node = $node->get_from_storage();

            #print $node->_abcd."\n";

            is(scalar $node->mobius_path, $rightmost_path . ($index + 2), "level $level / node $index mobius_path");

            $rightmost_node = $node if ($index == $test->{max_index});

        }

        $rightmost_path .= ($test->{max_index}+2). '.';

    }

    ok($x->[0]->[0] < $test->{int}, "max inner node is $test->{max_index}\n");

    if ($x->[0]->[0] < 2147483647) {

        is(scalar $rightmost_node->_abcd, 
           sprintf("(%dx + %d) / (%dx + %d)", $x->[0]->[0], $x->[0]->[1], $x->[1]->[0], $x->[1]->[1]),
           "check level $test->{depth} rightmost_node abcd with matrix");

    }

}

END {
    # In the END section so that the test DB file gets closed before we attempt to unlink it
    CdbiTreeTest::clear($schema);
}

1;
