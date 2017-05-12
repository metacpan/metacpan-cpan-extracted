# First test with SQLite: Basic Apache::Session usage
#!/usr/bin/perl

use strict;
use Test::More;
use File::Temp qw(mktemp);

my $dbfile = mktemp('tmp.db_XXXX');

plan skip_all => "DBD::SQLite is needed for this test"
  unless eval {
    require DBI;
    require DBD::SQLite;
    1;
  };

plan skip_all => "DBD::SQLite error : $@"
  unless eval {
    my $dbh;
    $dbh = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "" )
      or die $dbh->errstr;
    $dbh->do(
'CREATE TABLE sessions(id char(32) not null primary key,a_session text);'
    ) or die $dbh->errstr;
    $dbh->disconnect() or die $dbh->errstr;
  };

plan tests => 5;

use_ok('Apache::Session::Browseable::SQLite');

my %session;
ok(
    tie %session, 'Apache::Session::Browseable::SQLite',
    undef, { DataSource => "dbi:SQLite:$dbfile", Index => '' }
);

ok( $session{a} = 'foo' );
my $id = $session{_session_id};

untie %session;

ok(
    tie %session, 'Apache::Session::Browseable::SQLite',
    $id, { DataSource => "dbi:SQLite:$dbfile" }
);

ok( $session{a} eq 'foo' );

unlink $dbfile if ( -e $dbfile );

