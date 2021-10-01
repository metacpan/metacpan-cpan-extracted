#!/usr/bin/perl -w

BEGIN { $ENV{'TZ'} = 'Europe/Moscow' };

use strict;
use warnings;
use Test::More;
BEGIN { require "./t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 38;

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

my $handle;
my $skip_tz_tests;

foreach my $d ( @AvailableDrivers ) {
SKIP: {
    unless( has_schema( 'TestApp', $d ) ) {
        skip "No schema for '$d' driver", TESTS_PER_DRIVER;
    }
    unless( should_test( $d ) ) {
        skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
    }

    $handle = get_handle( $d );
    connect_handle( $handle );
    isa_ok($handle->dbh, 'DBI::db');

    diag "testing $d" if $ENV{'TEST_VERBOSE'};

    my $ret = init_schema( 'TestApp', $handle );
    isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back");

    my $count_all = init_data( 'TestApp::User', $handle );
    ok( $count_all,  "init users data" );

    is( $handle->DateTimeFunction, 'NULL', 'no type' );
    is( $handle->DateTimeFunction( Type => 'bad function' ), 'NULL', 'bad type' );

    is( $handle->ConvertTimezoneFunction( Field => '?' ), '?', 'no To argument' );
    is( $handle->ConvertTimezoneFunction( To => 'utc', Field => '?' ), '?', 'From and To equal' );

    $skip_tz_tests = 0;
    if ( $d eq 'SQLite' ) {
        my $check = '2013-04-01 16:00:00';
        my ($got) = $handle->dbh->selectrow_array("SELECT datetime(?,'localtime')", undef, $check);
        $skip_tz_tests = 1 if $got eq $check;
    }
    elsif ($d eq 'mysql') {
        my $check = '2013-04-01 16:00:00';
        my ($got) = $handle->dbh->selectrow_array(
            "SELECT CONVERT_TZ(?, ?, ?)", undef, $check, 'UTC', 'Europe/Moscow'
        );
        $skip_tz_tests = 1 if !$got || $got eq $check;
    }

    foreach my $type ('date time', 'DateTime', 'date_time', 'Date-Time') {
        run_test(
            { Type => $type },
            {
                '' => undef,
                '2011-05-20 19:53:23' => '2011-05-20 19:53:23',
            },
        );
        run_test(
            { Type => $type, Timezone => { To => 'Europe/Moscow' } },
            {
                '' => undef,
                '2011-05-20 19:53:23' => '2011-05-20 23:53:23',
                '2011-05-20 22:53:23' => '2011-05-21 02:53:23',
            },
        );
    }

    run_test(
        { Type => 'time' },
        {
            '' => undef,
            '2011-05-20 19:53:23' => '19:53:23',
        },
    );
    run_test(
        { Type => 'time', Timezone => { To => 'Europe/Moscow' } },
        {
            '' => undef,
            '2011-05-20 19:53:23' => '23:53:23',
            '2011-05-20 22:53:23' => '2:53:23',
        },
    );

    run_test( 
        { Type => 'hourly' },
        {
            '' => undef,
            '2011-05-20 19:53:23' => '2011-05-20 19',
            '2011-05-20 22:53:23' => '2011-05-20 22',
        },
    );
    run_test( 
        { Type => 'hourly', Timezone => { To => 'Europe/Moscow' } },
        {
            '' => undef,
            '2011-05-20 19:53:23' => '2011-05-20 23',
            '2011-05-20 22:53:23' => '2011-05-21 02',
        },
    );

    run_test(
        { Type => 'hour' },
        {
            '' => undef,
            '2011-05-20 19:53:23' => '19',
        },
    );
    run_test(
        { Type => 'hour', Timezone => { To => 'Europe/Moscow' } },
        {
            '' => undef,
            '2011-05-20 19:53:23' => '23',
            '2011-05-20 22:53:23' => '2',
        },
    );

    foreach my $type ( 'date', 'daily' ) {
        run_test(
            { Type => $type },
            {
                '' => undef,
                '2011-05-20 19:53:23' => '2011-05-20',
            },
        );
        run_test(
            { Type => $type, Timezone => { To => 'Europe/Moscow' } },
            {
                '' => undef,
                '2011-05-20 19:53:23' => '2011-05-20',
                '2011-05-20 22:53:23' => '2011-05-21',
            },
        );
    }

    run_test(
        { Type => 'day of week' },
        {
            '' => undef,
            '2011-05-20 19:53:23' => '5',
            '2011-05-21 19:53:23' => '6',
            '2011-05-22 19:53:23' => '0',
            '2011-05-20 22:53:23' => '5',
            '2011-05-21 22:53:23' => '6',
            '2011-05-22 22:53:23' => '0',
        },
    );
    run_test(
        { Type => 'day of week', Timezone => { To => 'Europe/Moscow' } },
        {
            '' => undef,
            '2011-05-20 19:53:23' => '5',
            '2011-05-21 19:53:23' => '6',
            '2011-05-22 19:53:23' => '0',
            '2011-05-20 22:53:23' => '6',
            '2011-05-21 22:53:23' => '0',
            '2011-05-22 22:53:23' => '1',
        },
    );


    foreach my $type ( 'day', 'DayOfMonth' ) {
        run_test(
            { Type => $type },
            {
                '' => undef,
                '2011-05-20 19:53:23' => '20',
                '2011-05-20 22:53:23' => '20',
            },
        );
        run_test(
            { Type => $type, Timezone => { To => 'Europe/Moscow' } },
            {
                '' => undef,
                '2011-05-20 19:53:23' => '20',
                '2011-05-20 22:53:23' => '21',
            },
        );
    }

    run_test(
        { Type => 'day of year' },
        {
            '' => undef,
            '2011-05-20 19:53:23' => '140',
            '2011-05-20 22:53:23' => '140',
        },
    );
    run_test(
        { Type => 'day of year', Timezone => { To => 'Europe/Moscow' } },
        {
            '' => undef,
            '2011-05-20 19:53:23' => '140',
            '2011-05-20 22:53:23' => '141',
        },
    );

    run_test(
        { Type => 'month' },
        {
            '' => undef,
            '2011-05-20 19:53:23' => 5,
        },
    );

    run_test(
        { Type => 'monthly' },
        {
            '' => undef,
            '2011-05-20 19:53:23' => '2011-05',
        },
    );

    foreach my $type ( 'year', 'annually' ) {
        run_test(
            { Type => $type },
            {
                '' => undef,
                '2011-05-20 19:53:23' => '2011',
            },
        );
    }

    run_test(
        { Type => 'week of year' },
        {
            '' => undef,
            '2011-05-20 19:53:23' => '20',
        },
    );

    cleanup_schema( 'TestApp', $handle );
}} # SKIP, foreach blocks


sub run_test {
    my $props = shift;
    my $expected = shift;

    SKIP: {
        skip "skipping timezone tests", 1
            if $props->{'Timezone'} && $skip_tz_tests;

        my $users = TestApp::Users->new( $handle );
        $users->UnLimit;
        $users->Column( FIELD => 'Expires' );
        my $column = $users->Column(
            ALIAS => 'main',
            FIELD => 'Expires',
            FUNCTION => $users->_Handle->DateTimeFunction( %$props ),
        );

        my %got;
        while ( my $user = $users->Next ) {
            $got{ $user->Expires || '' } = $user->__Value( $column );
        }
        foreach my $key ( keys %got ) {
            delete $got{ $key } unless exists $expected->{ $key };

            $got{ $key } =~ s/^0+(?!$)// if defined $got{ $key };
        }
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        is_deeply( \%got, $expected, "correct ". $props->{'Type'} ." function" )
            or diag "wrong SQL: ". $users->BuildSelectQuery;
    }
}

1;

package TestApp;

sub schema_mysql {
<<EOF;
CREATE TEMPORARY TABLE Users (
    id integer AUTO_INCREMENT,
    Expires DATETIME NULL,
    PRIMARY KEY (id)
)
EOF

}

sub schema_pg {
<<EOF;
CREATE TEMPORARY TABLE Users (
    id serial PRIMARY KEY,
    Expires TIMESTAMP NULL
)
EOF

}

sub schema_sqlite {

<<EOF;
CREATE TABLE Users (
    id integer primary key,
    Expires TEXT NULL
)
EOF

}

sub schema_oracle { [
    "CREATE SEQUENCE Users_seq",
    "CREATE TABLE Users (
        id integer CONSTRAINT Users_Key PRIMARY KEY,
        Expires DATE NULL
    )",
] }

sub cleanup_schema_oracle { [
    "DROP SEQUENCE Users_seq",
    "DROP TABLE Users",
] }


1;

package TestApp::User;

use base $ENV{SB_TEST_CACHABLE}?
    qw/DBIx::SearchBuilder::Record::Cachable/:
    qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self = shift;
    my $handle = shift;
    $self->Table('Users');
    $self->_Handle($handle);
}

sub _ClassAccessible {
    {   
        id =>
        {read => 1, type => 'int(11)' }, 
        Expires =>
        {read => 1, write => 1, type => 'datetime' },
    }
}

sub init_data {
    return (
    [ 'Expires'             ],
    [  undef                ],
    [ '2011-05-20 19:53:23' ], # friday
    [ '2011-05-21 19:53:23' ], # saturday
    [ '2011-05-22 19:53:23' ], # sunday
    [ '2011-05-20 22:53:23' ], # fri in UTC, sat in moscow
    [ '2011-05-21 22:53:23' ], # sat in UTC, sun in moscow
    [ '2011-05-22 22:53:23' ], # sun in UTC, mon in moscow
    );
}

1;

package TestApp::Users;

# use TestApp::User;
use base qw/DBIx::SearchBuilder/;

sub _Init {
    my $self = shift;
    $self->SUPER::_Init( Handle => shift );
    $self->Table('Users');
}

sub NewItem
{
    my $self = shift;
    return TestApp::User->new( $self->_Handle );
}

1;


