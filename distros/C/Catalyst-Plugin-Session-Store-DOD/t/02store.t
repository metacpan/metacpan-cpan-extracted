#!/usr/bin/perl
use strict;

use File::Path;
use FindBin;
use Test::More tests => 2;

# create the database
my $db_file = "$FindBin::Bin/tmp/session.db";
unless ( -e $db_file ) {
    mkdir "$FindBin::Bin/tmp" or die $!;
    my $sql =
      'CREATE TABLE sessions (id TEXT PRIMARY KEY, session_data TEXT, expires INT);';
    my $dbh = DBI->connect("dbi:SQLite:$db_file") or die $DBI::errstr;
    $dbh->do($sql);
    $dbh->disconnect;
}

use lib "$FindBin::Bin/lib";
use TestApp::M::Session;

my $session = TestApp::M::Session->new(
    id           => 'foo',
    session_data => 'bar',
    expires      => 1234,
);
ok($session->save, "saved new session");

$session = TestApp::M::Session->lookup('foo');
is($session->session_data, 'bar', 'got the session data');

rmtree "$FindBin::Bin/tmp";

1;
