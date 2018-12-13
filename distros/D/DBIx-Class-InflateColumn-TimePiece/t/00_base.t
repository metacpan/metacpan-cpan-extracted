#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use Test::More;
use Scalar::Util qw/blessed/;

use lib dirname(__FILE__) . '/lib';
use TimePieceDB;

local $ENV{TZ} = 'UTC';

if ( !eval { require DBD::SQLite } ) {
    plan skip_all => 'DBD::SQLite is not installed!';
}

my $schema = TimePieceDB->init_schema;
my $rs     = $schema->resultset('TestUser');

my @tests = (
    [ 0,             '1970-01-01' ],
    [ 25 * 60 * 60 , '1970-01-02' ],
    [ 1544536942,    '2018-12-11' ],
    [ 1544536942,    '2018-12-11 14:02:22', sub { sprintf "%s %s", $_[0]->ymd, $_[0]->hms } ],
    [ -1,            '1969-12-31' ],
    [ 1544536942,    '11-12-2018', sub { $_[0]->dmy } ],
);

my $default = sub { $_[0]->ymd };

my $cnt = 0;
for my $test ( @tests ) {
    my ($input, $output, $code) = @{ $test };

    my %opt;

    if ( $cnt % 2 ) {
        $opt{last_login} = time;
    }

    my $testuser = $rs->create({
        user_name    => 'hugo',
        city         => 'anywhere',
        user_created => $input,
        %opt,
    });

    my $sub = $code // $default;

    ok blessed $testuser, "$cnt - testuser is an object";
    ok !blessed $testuser->id, "$cnt - id column is not an object";
    ok !blessed $testuser->user_name, "$cnt - user_name is not an object";
    ok !blessed $testuser->city, "$cnt - city is not an object";
    ok blessed $testuser->user_created, "$cnt - user_created IS an object";

    if ( %opt ) {
        ok blessed $testuser->last_login, "$cnt - last_login IS an object";
        like $testuser->last_login->ymd, qr/\A\d{4}-\d{2}-\d{2}\z/, "$cnt - last_login returns a date";
    }
    else {
        is $testuser->last_login, undef, "$cnt - last_login is undef";
    }

    is $sub->( $testuser->user_created ), $output, "In: $input // Out: $output";
}

done_testing();
