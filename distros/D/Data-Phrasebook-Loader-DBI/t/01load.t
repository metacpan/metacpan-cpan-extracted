#!/usr/bin/perl -w
use strict;
use lib 't';
use BookDB;

use Test::More tests => 33;

# ------------------------------------------------------------------------

my $class = 'Data::Phrasebook::Loader::DBI';
use_ok($class);

my $dbh = BookDB->new();
my $dsn = 'dbi:Mock:database=test';
my $dict = 'BASE';

my ($mock,$nomock);

BEGIN {
    eval "use Test::MockObject";
    $nomock = $@;

    if(!$nomock) {
        $mock = Test::MockObject->new();
        $mock->fake_module( 'DBI',
                    'connect'           => \&BookDB::connect,
                    'disconnect'        => \&BookDB::disconnect,
                    'prepare'           => \&BookDB::prepare,
                    'prepare_cached'    => \&BookDB::prepare_cached,
                    'rebind'            => \&BookDB::rebind,
                    'bind_param'        => \&BookDB::bind_param,
                    'execute'           => \&BookDB::execute,
                    'fetchrow_hashref'  => \&BookDB::fetchrow_hashref,
                    'fetchall_arrayref' => \&BookDB::fetchall_arrayref,
                    'fetchrow_array'    => \&BookDB::fetchrow_array,
                    'finish'            => \&BookDB::finish
        );
        $mock->fake_new( 'DBI' );
        $mock->mock( 'connect',             \&BookDB::connect );
        $mock->mock( 'disconnect',          \&BookDB::disconnect );
        $mock->mock( 'prepare',             \&BookDB::prepare );
        $mock->mock( 'prepare_cached',      \&BookDB::prepare_cached );
        $mock->mock( 'rebind',              \&BookDB::rebind );
        $mock->mock( 'bind_param',          \&BookDB::bind_param );
        $mock->mock( 'execute',             \&BookDB::execute );
        $mock->mock( 'fetchrow_hashref',    \&BookDB::fetchrow_hashref );
        $mock->mock( 'fetchall_arrayref',   \&BookDB::fetchall_arrayref );
        $mock->mock( 'fetchrow_array',      \&BookDB::fetchrow_array );
        $mock->mock( 'finish',              \&BookDB::finish );
    }
}

# ------------------------------------------------------------------------

SKIP: {
    skip "Test::MockObject required for testing", 32 if $nomock;

    {
        my $obj = $class->new();
        isa_ok($obj, $class, 'Checking class');

        eval { $obj->load(); };
        ok($@, 'Test load failed - no file');

        my $file = {
            dbh       => $dbh,
            dbcolumns => ['keyword','phrase','dictionary'],
        };

        eval { $obj->load( $file ); };
        ok($@, 'Test load failed - no table');
    }

    {
        my $obj = $class->new();

        my $file = {
            dbh       => $dbh,
            dbtable   => 'phrasebook',
        };

        eval { $obj->load( $file ); };
        ok($@, 'Test load failed - no columns');
    }

    {
        my $obj = $class->new();

        my $file = {
            dbtable   => 'phrasebook',
            dbcolumns => ['keyword','phrase','dictionary'],
        };

        eval { $obj->load( $file ); };
        ok($@, 'Test load failed - no handle');
    }

    {
        my $obj = $class->new();

        my $file = {
            dsn       => $dsn,
            dbtable   => 'phrasebook',
            dbcolumns => ['keyword','phrase','dictionary'],
        };

        eval { $obj->load( $file ); };
        ok($@, 'Test load failed - dsn with no user/password');
    }

    {
        my $obj = $class->new();

        my $file = {
            dsn       => $dsn,
            dbuser    => 'user',
            dbtable   => 'phrasebook',
            dbcolumns => ['keyword','phrase','dictionary'],
        };

        eval { $obj->load( $file ); };
        ok($@, 'Test load failed - dsn with no password');
    }

    {
        my $obj = $class->new();

        my $file = {
            dsn       => $dsn,
            dbuser    => 'user',
            dbpass    => 'pass',
            dbtable   => 'phrasebook',
            dbcolumns => ['keyword','phrase','dictionary'],
        };

        eval { $obj->load( $file ); };
        is($@,'','Test load passed - dsn');
    }

    {
        my $obj = $class->new();

        my $file = {
            dbh       => $dbh,
            dbtable   => 'phrasebook',
            dbcolumns => [],
        };

        eval { $obj->load( $file ); };
        ok($@,'Test load failed - empty column list');
    }

    {
        my $obj = $class->new();

        my $file = {
            dbh       => $dbh,
            dbtable   => 'phrasebook',
            dbcolumns => ['keyword','phrase'],
        };

        load_test($obj, 0, $file );
    }

    {
        my $obj = $class->new();

        my $file = {
          dbh       => $dbh,
          dbtable   => 'phrasebook',
          dbcolumns => ['keyword','phrase','dictionary'],
        };

        load_test($obj, 0, $file );
        load_test($obj, 0, $file, 'BLAH' );
        load_test($obj, 0, $file, $dict );
        load_test($obj, 0, $file, ['ONE','TWO','THREE'] );

        my @expected = qw(DEF ONE);
        my @dicts = $obj->dicts();
        is_deeply( \@dicts, \@expected, 'Checking dictionaries' );

           @expected = qw(bar foo);
        my @keywords = $obj->keywords();
        is_deeply( \@keywords, \@expected, 'Checking keywords' );
    }

    {
        my $obj = $class->new();

        my $file = {
          dbh       => $dbh,
          dbtable   => 'phrasebook',
          dbcolumns => ['keyword','phrase'],
        };

        eval { $obj->load( $file ); };
        my @expected = qw();
        my @dicts = $obj->dicts();
        is_deeply( \@dicts, \@expected, 'no dictionaries when no dictionary column specified' );
    }
}

sub load_test {
    my $obj  = shift;
    my $fail = shift;   # do we expect the test to fail?

    eval { $obj->load( @_ ); };
    $fail ? ok($@,  "Test load failed - not enough data [@_]")
          : ok(!$@, "Test load passed - valid params [@_]");

    my $phrase = $obj->get();
    is($phrase, undef, '.. no key no phrase');
    $phrase = $obj->get('bogus');
    is($phrase, undef, '.. unknown key no phrase');
    $phrase = $obj->get('foo');
    like($phrase, qr/Welcome to/, '.. a welcome phrase');
}
