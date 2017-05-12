# -*- perl -*-

# t/test1.t - 1st test

use Class::C3;
use strict;
use Test::More;
use Test::Exception;
use warnings;
no warnings qw(once);

use lib qw(t/lib);

use DATest;
use DATest::Schema;

BEGIN {
    eval "use DBD::SQLite";
    plan $@
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 7 );
}

use lib qw(t/lib);

my $schema = DATest->init_schema();

my $b1 = $schema->resultset('Test1B')->create({
    name    => 'B.1',
});

my $a1 = $schema->resultset('Test1A')->create({
    name    => 'A.1',
    b       => $b1
});
my $a2 = $schema->resultset('Test1A')->create({
    name    => 'A.2',
    b       => $b1
});
my $a3 = $schema->resultset('Test1A')->create({
    name    => 'A.3',
    b       => $b1
});
my $a4 = $schema->resultset('Test1A')->create({
    name    => 'A.4',
    b       => undef
});

is($schema->resultset('Test1B')->count,1);
is($schema->resultset('Test1A')->count,4);

throws_ok {
    $a1->delete()
} qr/Can't delete the object because it is still referenced from/, 'deny exception';

$a4->delete();

is($schema->resultset('Test1A')->count,3);

$b1->delete();
is($schema->resultset('Test1B')->count,0);
is($schema->resultset('Test1A')->count,3);
is($schema->resultset('Test1A')->search({ b => \'IS NULL' })->count,3);
