use strict;
use warnings;

use Path::Tiny qw( cwd tempdir );

use lib cwd->child( qw( t lib ) )->stringify;

use Test::More import => [ qw( BAIL_OUT is note ok plan subtest use_ok ) ];
use Test::Output qw( stdout_is );
use Test::PgTAP import => [ qw( tables_are triggers_are ) ];

use POSIX qw( EXIT_SUCCESS );

eval { require Test::PostgreSQL };
plan skip_all => 'Test::PostgreSQL required' unless $@ eq '';

my $pgsql = eval { Test::PostgreSQL->new } or do {
  no warnings 'once';
  plan skip_all => $Test::PostgreSQL::errstr;
};

note 'managed schema: ',  my $managed_schema  = 'myschema';
note 'tracking schema: ', my $tracking_schema = 'public';
note 'tracking table',    my $tracking_table  = 'migrations';
note 'dsn: ',             my $dsn             = $pgsql->dsn;
local $Test::PgTAP::Dbh = DBI->connect( $dsn . ";options=--search_path=$managed_schema" );

plan tests => 8;

require DBIx::Migration::CLI;

ok my $coderef = DBIx::Migration::CLI->can( 'run' ), 'has "run" subroutine';

my $dir = cwd->child( qw( t sql trigger ) );

subtest 'migrate to version 0' => sub {
  plan tests => 2;

  my $got_exitval;
  stdout_is { $got_exitval = $coderef->( '-s', $managed_schema, '-T', $tracking_table, $dsn, $dir, 0 ) } '',
    'check stdout';
  is $got_exitval, EXIT_SUCCESS, 'check exit value';
};

subtest 'migrate to latest version' => sub {
  plan tests => 2;

  my $got_exitval;
  stdout_is { $got_exitval = $coderef->( '-s', $managed_schema, '-T', $tracking_table, $dsn, $dir ) } '',
    'check stdout';
  is $got_exitval, EXIT_SUCCESS, 'check exit value';
};

my $target_version = 2;
subtest 'version is latest' => sub {
  plan tests => 2;

  my $got_exitval;
  stdout_is { $got_exitval = $coderef->( '-s', $managed_schema, '-T', $tracking_table, $dsn ) } "$target_version\n",
    'check stdout';
  is $got_exitval, EXIT_SUCCESS, 'check exit value';
};

tables_are $managed_schema, [ qw( products product_price_changes ) ], 'Check tables';
tables_are [ "$tracking_schema.$tracking_table", map { "$managed_schema.$_" } qw( products product_price_changes ) ];
triggers_are $managed_schema, 'products', [ qw( price_changes ) ];
triggers_are 'products', [ "$managed_schema.price_changes" ];
