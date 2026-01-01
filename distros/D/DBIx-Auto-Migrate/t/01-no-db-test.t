#!/usr/bin/env perl

use v5.16.3;
use strict;
use warnings;

use Test::More;
use Test::PostgreSQL;
use Test::Exception;
use Test::MockModule;
use Test::MockObject;
use Data::Dumper;

my $create_index = sub {
    my ( $table, $column ) = @_;
    if ( !$table ) {
        die 'Index requires table';
    }
    if ( !$column ) {
        die 'Index requires column';
    }
    return "CREATE INDEX index_${table}_${column} ON $table ($column)";

};
{
    my %queries;
    my $test_db           = Test::MockObject->new;
    my $current_migration = undef;
    $test_db->mock(
        do => sub {
            shift;
            my $query = shift;
            my $undef = shift;
            my @args  = @_;
            $queries{$query} = [@args];
            if (
                $query eq 'INSERT INTO options (name, value)
VALUES (?, ?) 
'
              )
            {
                my ( $undef, $value ) = @args;
                $current_migration = $value;
            }
	    #            print Data::Dumper::Dumper \%queries;
            return 1;
        }
    );
    $test_db->mock(
        selectrow_hashref => sub {
            return { value => $current_migration };
        }
    );
    my $test_dbi = Test::MockModule->new('DBI');
    $test_dbi->mock(
        'connect'        => sub { $test_db },
        'connect_cached' => sub { $test_db }
    );
    my $dsn  = 'dbi:Pg:dbname=hola';
    my $user = 'postgres';
    my $pass = undef;

    package MyCompany::DB2 {
        use v5.16.3;
        use strict;
        use warnings;

        use DBIx::Auto::Migrate;

        finish_auto_migrate;

        sub migrations {
            return (
                'CREATE table options (
					id BIGSERIAL PRIMARY KEY,
					name TEXT NOT NULL,
					value TEXT NOT NULL,
					UNIQUE (name),
					UNIQUE (value)
				)',
                $create_index->(qw/options name/),
                'CREATE TABLE users (
					id BIGSERIAL PRIMARY KEY
				)',
            );
        }

        sub dsn {
            return $dsn;
        }

        sub user {
            return $user;
        }

        sub pass {
            return $pass;
        }
    }
    MyCompany::DB2->connect;
    is_deeply \%queries,
    {
        'CREATE table options (
					id BIGSERIAL PRIMARY KEY,
					name TEXT NOT NULL,
					value TEXT NOT NULL,
					UNIQUE (name),
					UNIQUE (value)
				)' => [],
        'CREATE INDEX index_options_name ON options (name)' => [],
        'INSERT INTO options (name, value)
VALUES (?, ?) 
' => [ 'current_migration', 3 ],
        'CREATE TABLE users (
					id BIGSERIAL PRIMARY KEY
				)' => []
      },
      'Queries match';
    is $current_migration, 3, 'Migration matches';

}
done_testing;
1;
