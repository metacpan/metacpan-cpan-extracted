# -*- perl -*-

# t/test2.t - 2nd test

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
        : ( tests => 35 );
}

use lib qw(t/lib);

my $schema = DATest->init_schema();

my $c1 = $schema->resultset('Test2C')->create({
    name    => 'C.1',
});
my $c2 = $schema->resultset('Test2C')->create({
    name    => 'C.2',
});
my $c3 = $schema->resultset('Test2C')->create({
    name    => 'C.3',
});

my $d1 = $schema->resultset('Test2D')->create({
    name    => 'D.1',
    c       => $c2,
});
my $d2 = $schema->resultset('Test2D')->create({
    name    => 'D.2',
    c       => $c3,
});

my $b1 = $schema->resultset('Test2B')->create({
    name    => 'B.1',
    c       => $c1,
});
my $b2 = $schema->resultset('Test2B')->create({
    name    => 'B.2',
    c       => $c3,
});
my $b3 = $schema->resultset('Test2B')->create({
    name    => 'B.3',
    c       => $c2
});


my $a1 = $schema->resultset('Test2A')->create({
    name    => 'A.1',
    b       => $b1
});
my $a2 = $schema->resultset('Test2A')->create({
    name    => 'A.2',
    b       => $b1
});
my $a3 = $schema->resultset('Test2A')->create({
    name    => 'A.3',
    b       => $b2
});
my $a4 = $schema->resultset('Test2A')->create({
    name    => 'A.4',
    b       => undef
});

is($schema->resultset('Test2D')->count,2);
is($schema->resultset('Test2C')->count,3);
is($schema->resultset('Test2B')->count,3);
is($schema->resultset('Test2A')->count,4);
is($schema->resultset('Test2A')->search({b => \'IS NULL'})->count,1);

warnings_like {
    $a1->delete();
} [qr/TESTME/];

is($schema->resultset('Test2D')->count,2);
is($schema->resultset('Test2C')->count,3);
is($schema->resultset('Test2B')->count,2);
is($schema->resultset('Test2A')->count,3);
is($schema->resultset('Test2A')->search({b => \'IS NULL'})->count,2);

throws_ok {
    #$schema->txn_do(sub {
        $b2->delete({extra => 'bunny'});
    #})
} qr/TESTME:bunny/, 'call method';

warnings_like {
    $b2->delete();
} [qr/TESTME/];

is($schema->resultset('Test2D')->count,2);
is($schema->resultset('Test2C')->count,3);
is($schema->resultset('Test2B')->count,1);
is($schema->resultset('Test2A')->count,3);
is($schema->resultset('Test2A')->search({b => \'IS NULL'})->count,3);

throws_ok {
    $c2->delete()
} qr/Can't delete the object because it is still referenced from/, 'deny exception';

is($schema->resultset('Test2D')->count,2);
is($schema->resultset('Test2C')->count,3);
is($schema->resultset('Test2B')->count,1);
is($schema->resultset('Test2A')->count,3);
is($schema->resultset('Test2A')->search({b => \'IS NULL'})->count,3);

$d2->delete();

is($schema->resultset('Test2D')->count,1);
is($schema->resultset('Test2C')->count,2);
is($schema->resultset('Test2B')->count,1);
is($schema->resultset('Test2A')->count,3);
is($schema->resultset('Test2A')->search({b => \'IS NULL'})->count,3);

throws_ok {
    $d1->delete();
} qr/Can't delete the object because it is still referenced from/, 'deny exception';


is($schema->resultset('Test2D')->count,1);
is($schema->resultset('Test2C')->count,2);
is($schema->resultset('Test2B')->count,1);
is($schema->resultset('Test2A')->count,3);
is($schema->resultset('Test2A')->search({b => \'IS NULL'})->count,3);
