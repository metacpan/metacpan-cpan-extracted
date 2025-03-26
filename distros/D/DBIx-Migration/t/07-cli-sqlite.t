use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT is ok plan subtest use_ok ) ], tests => 13;
use Test::Output qw( stderr_like stdout_is stdout_like );

use Path::Tiny qw( cwd tempdir );
use POSIX      qw( EXIT_FAILURE EXIT_SUCCESS );

my $module;

BEGIN {
  $module = 'DBIx::Migration::CLI';
  use_ok( $module ) or BAIL_OUT "Cannot load module '$module'!";
}

ok my $coderef = $module->can( 'run' ), 'has "run" subroutine';

subtest '-V' => sub {
  plan tests => 2;

  my $got_exitval;
  stdout_is { $got_exitval = $coderef->( '-V' ) } "Version:\n  0.23\n\n", 'check stdout';
  is $got_exitval, EXIT_SUCCESS, 'check exit value';
};

subtest '-h' => sub {
  plan tests => 2;

  my $got_exitval;
  stdout_like { $got_exitval = $coderef->( '-h' ) } qr/\AUsage:.+Options:.+Arguments:.+/s, 'check stdout';
  is $got_exitval, EXIT_SUCCESS, 'check exit value';
};

subtest 'missing mandatory arguments' => sub {
  plan tests => 2;

  my $got_exitval;
  stderr_like { $got_exitval = $coderef->() } qr/\AMissing mandatory arguments\nUsage:.+/s, 'check stderr';
  is $got_exitval, 2, 'check exit value';
};

subtest 'unknown option' => sub {
  plan tests => 2;

  my $got_exitval;
  stderr_like { $got_exitval = $coderef->( '-g' ) } qr/\AUnknown option: g\nUsage:.+/s, 'check stderr';
  is $got_exitval, 2, 'check exit value';
};

subtest 'missing database file' => sub {
  plan tests => 2;

  my $got_exitval;
  stderr_like { $got_exitval = $coderef->( 'dbi:SQLite:dbname=./t/missing/test.db' ) }
  qr/unable to open database file.+\nUsage:.+/s, 'check stderr';
  is $got_exitval, 2, 'check exit value';
};

my $tempdir = tempdir( CLEANUP => 1 );
my $dsn     = 'dbi:SQLite:dbname=' . $tempdir->child( 'test.db' );
subtest 'version is undefined' => sub {
  plan tests => 2;

  my $got_exitval;
  stdout_is { $got_exitval = $coderef->( $dsn ) } "\n", 'check stdout';
  is $got_exitval, EXIT_SUCCESS, 'check exit value';
};

my $dir = cwd->child( qw( t sql advanced ) );
subtest 'migrate to version 0' => sub {
  plan tests => 2;

  my $got_exitval;
  stdout_is { $got_exitval = $coderef->( $dsn, $dir, 0 ) } '', 'check stdout';
  is $got_exitval, EXIT_SUCCESS, 'check exit value';
};

subtest 'version is 0' => sub {
  plan tests => 2;

  my $got_exitval;
  stdout_is { $got_exitval = $coderef->( $dsn ) } "0\n", 'check stdout';
  is $got_exitval, EXIT_SUCCESS, 'check exit value';
};

subtest 'migrate to latest version' => sub {
  plan tests => 2;

  my $got_exitval;
  stdout_is { $got_exitval = $coderef->( $dsn, $dir ) } '', 'check stdout';
  is $got_exitval, EXIT_SUCCESS, 'check exit value';
};

subtest 'version is latest' => sub {
  plan tests => 2;

  my $got_exitval;
  stdout_is { $got_exitval = $coderef->( $dsn ) } "3\n", 'check stdout';
  is $got_exitval, EXIT_SUCCESS, 'check exit value';
};

subtest 'migrate to missing version' => sub {
  plan tests => 2;

  my $got_exitval;
  stdout_is { $got_exitval = $coderef->( $dsn, $dir, 4 ) } '', 'check stdout';
  is $got_exitval, EXIT_FAILURE, 'check exit value';
};
