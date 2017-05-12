# -*- perl -*-

# t/test4.t - 4th test

use Class::C3;
use strict;
use Test::More;
use Test::Exception;
use Test::Warn;
use warnings;
no warnings qw(once);

use lib qw(t/lib);

use DATest;
use DATest::Schema;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 6 );
}

use lib qw(t/lib);

my $schema = DATest->init_schema();

my $a1 = $schema->resultset('Test5A')->create({
    name    => 'A.1',
});
my $a2 = $schema->resultset('Test5A')->create({
    name    => 'A.2',
});

my $b1 = $schema->resultset('Test5B')->create({
    name    => 'B.2',
    a1      => $a1->id,
    a2      => $a2->id
});
my $b2 = $schema->resultset('Test5B')->create({
    name    => 'B.2',
    a1       => $a1->id,
    a2       => $a2->id
});
my $b3 = $schema->resultset('Test5B')->create({
    name    => 'B.3',
    a1       => $a2->id,
    a2       => $a1->id
});


is($schema->resultset('Test5A')->count,2);
is($schema->resultset('Test5B')->count,3);

$a1->delete();

is($schema->resultset('Test5A')->count,1);
is($schema->resultset('Test5A')->count,1);

$a2->delete();

is($schema->resultset('Test5A')->count,0);
is($schema->resultset('Test5A')->count,0);