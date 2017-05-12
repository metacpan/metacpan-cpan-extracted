#!perl

use strict;
use warnings;
use Test::More;

use DBI;
use SQL::Statement 1.401; # to make our 'SELECT 1 AS num' query work

use lib 'lib';
use DBIx::Iterator;

my $dbh = DBI->connect('dbi:DBM:dbm_type=DB_File');
my $db = DBIx::Iterator->new($dbh);
{
    my $st = $db->prepare('SELECT 1 AS num');
    can_ok($st, 'execute');

    my $it = $st->execute();
    isa_ok($it, 'CODE');

    my $row = $it->();
    isa_ok($row, 'HASH');
    is( $row->{'num'}, 1, 'First iteration gives correct value' );

    is( $it->(), undef, 'Second iteration should be undef' );
}

{
    my $st = $db->prepare('SELECT ? AS mine');
    can_ok($st, 'bind_param', 'execute');
    $st->bind_param(1, 'foo');
    my $it = $st->execute();
    isa_ok($it, 'CODE');

    my ($row, $returned_st) = $it->();
    isa_ok($row, 'HASH');
    is( $row->{'mine'}, 'foo', 'First iteration gives correct value' );
    is( $returned_st, $st, 'List context also returns statement object' );

    my ($row2, $st2) = $it->();
    is( $row2, undef, 'Second iteration result should be undef' );
    is( $st2, $st, 'List context should still return statement object' );
}

{
    my $it = $db->query("SELECT ? AS mine", 'testing');
    isa_ok($it, 'CODE');
    my ($row, $st) = $it->();
    isa_ok($row, 'HASH');
    is( $row->{'mine'}, 'testing', 'Performing a query with placeholders work' );
    my ($row2, $st2) = $it->();
    is( $row2, undef, 'And iterator exhausts properly' );
    can_ok($st2, 'sth');
    is( $st2->sth->rows(), 1, 'Total amount of rows requested was 1' );
}

done_testing();
