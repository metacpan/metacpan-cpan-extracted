# -*- perl -*-

# t/test3.t - 3rd test

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
        : ( tests => 5 );
}

use lib qw(t/lib);

my $schema = DATest->init_schema();

my $a1 = $schema->resultset('Test3A')->create({
    name    => 'A.1',
});
my $a2 = $schema->resultset('Test3A')->create({
    name    => 'A.2',
    a       => $a1->id
});

$a1->update({
    a   => $a2->id,
});

my $a3 = $schema->resultset('Test3A')->create({
    name    => 'A.1',
});
$a3->update({
    a   => $a3->id,
});

is($schema->resultset('Test3A')->count,3);

$a1->delete();

is($schema->resultset('Test3A')->count,1);

$a3->delete();

is($schema->resultset('Test3A')->count,0);

my $a4 = $schema->resultset('Test3A')->create({
    name    => 'A.4',
});
my $a5 = $schema->resultset('Test3A')->create({
    name    => 'A.5',
    a       => $a4->id,
});
my $a6 = $schema->resultset('Test3A')->create({
    name    => 'A.6',
    a       => $a5->id
});
my $a7 = $schema->resultset('Test3A')->create({
    name    => 'A.7',
    a       => $a6->id
});

is($schema->resultset('Test3A')->count,4);

$a7->delete();

is($schema->resultset('Test3A')->count,0);