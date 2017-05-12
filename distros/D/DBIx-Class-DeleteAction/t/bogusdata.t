# -*- perl -*-

# t/bogusdata.t - bogus data test

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
        : ( tests => 2 );
}

my $schema = DATest->init_schema();

my $bx = $schema->resultset('Test1B')->new({
    name    => 'B.x',
});

throws_ok {
    $bx->delete;
} qr/Not in database/, 'Not in database';


my $ax = $schema->resultset('Test4A')->create({
    name    => 'A.x',
});

my $ay = $schema->resultset('Test4A')->create({
    name    => 'A.y',
    a       => $ax
});

throws_ok {
    $ay->delete;
} qr/Invalid delete action 'bogus'/, 'Invalid delete action';