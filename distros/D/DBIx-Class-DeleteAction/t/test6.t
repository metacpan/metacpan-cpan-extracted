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
        : ( tests => 8 );
}

use lib qw(t/lib);

my $schema = DATest->init_schema();

my $b1 = $schema->resultset('Test6B')->create({
    name    => 'B.1',
});
my $b2 = $schema->resultset('Test6B')->create({
    name    => 'B.2',
});
my $a1 = $schema->resultset('Test6A')->create({
    name    => 'A.1',
    b       => $b1
});
my $a2 = $schema->resultset('Test6A')->create({
    name    => 'A.2',
    b       => $b1
});
my $a3 = $schema->resultset('Test6A')->create({
    name    => 'A.3',
    b       => $b1
});


is($schema->resultset('Test6A')->count,3);
is($schema->resultset('Test6B')->count,2);

$a3->delete();

is($schema->resultset('Test6A')->count,2);
is($schema->resultset('Test6B')->count,2);

$b2->delete();

is($schema->resultset('Test6A')->count,2);
is($schema->resultset('Test6B')->count,1);

$b1->delete();

is($schema->resultset('Test5A')->count,0);
is($schema->resultset('Test5A')->count,0);