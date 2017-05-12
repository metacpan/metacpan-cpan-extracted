#!/usr/bin/perl 

use strict;
use warnings;

use FindBin qw($Bin);

system("sh $Bin/init_db.sh");

use Test::More;
use Test::Deep;
use Data::Dumper;

use DBIx::MultiDB;

my $query = DBIx::MultiDB->new(
    dsn => 'dbi:SQLite:dbname=/tmp/db1.db',
    sql => 'SELECT id, name, company_id FROM employee',
);

$query->left_join(
    dsn           => 'dbi:SQLite:dbname=/tmp/db2.db',
    sql           => 'SELECT id AS company_id, name AS company_name FROM company',
    key           => 'company_id',
    referenced_by => 'company_id',
);

$query->execute();

my @result;
while ( my $r = $query->fetchrow_hashref ) {
    push @result, $r;
}

my @expected_result = (
    {
        'company_id'   => '1',
        'company_name' => 'a',
        'name'         => 'a1',
        'id'           => '1'
    },
    {
        'company_id'   => '1',
        'company_name' => 'a',
        'name'         => 'a2',
        'id'           => '2'
    },
    {
        'company_id'   => '2',
        'company_name' => 'b',
        'name'         => 'b1',
        'id'           => '3'
    },
    {
        'company_id'   => '2',
        'company_name' => 'b',
        'name'         => 'b2',
        'id'           => '4'
    },
    {
        'company_id'   => '3',
        'company_name' => 'c',
        'name'         => 'c1',
        'id'           => '5'
    },
    {
        'company_id'   => '3',
        'company_name' => 'c',
        'name'         => 'c2',
        'id'           => '6'
    }
);

plan tests => 1;

cmp_deeply( \@result, \@expected_result )
  or print Dumper \@result;
