# -*- perl -*-

# t/006_relation.t -- Test relationship stuff

use Class::C3;
use strict;
use Test::More;
use warnings;
no warnings qw(once);

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 3 );
}

use lib qw(t/lib);

use_ok( 'VCTest' );

use_ok( 'VCTest::Schema' );

my $schema = VCTest->init_schema();

# Make sure we can still get a Test2 w/o adding a virtual column
my $test3;
eval { $test3 = $schema->resultset('Test2')->create({
    id      => "12",
    name    => "nayme",
    test3   => {
        id      => "12",
        name    => "other nayme",
    },
}); };
ok( !$@, 'Create row with relation that has loaded VC but has no VCs defined' )
or diag ( $@ );


