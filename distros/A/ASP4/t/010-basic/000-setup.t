#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use DBI;
use Digest::MD5 'md5_hex';

my $temp_root = '/tmp';
if( $^O =~ m{win32}i )
{
  $temp_root = $ENV{TEMP} || $ENV{TMP};
}# end if()

my $dbfile = "$temp_root/db_asp4";
open my $ofh, '>', $dbfile
  or die "Cannot open '$dbfile' for writing: $!";
binmode($ofh);
SCOPE: {
  no warnings 'uninitialized';
  print $ofh undef;
};
close($ofh);

my $dbh = DBI->connect("DBI:SQLite:dbname=$dbfile", "", "", {
  RaiseError => 1,
});

$dbh->do(<<"SQL");
drop table if exists asp_sessions
SQL

my $ok = $dbh->do(<<"SQL");
create table asp_sessions (
  session_id    char(32) not null primary key,
  modified_on   timestamp not null default( datetime('now','localtime') ),
  created_on    datetime not null default( datetime('now','localtime') ),
  session_data  blob
)
SQL

ok($ok, "created table");

my $id = md5_hex( rand() );
$dbh->do(<<"SQL");
insert into asp_sessions (session_id, session_data) values ('$id','test')
SQL

my $sth = $dbh->prepare("SELECT * FROM asp_sessions WHERE session_id = ?");
$sth->execute( $id );
ok( my $rec = $sth->fetchrow_hashref, "fetched record" );
$sth->finish();

$dbh->disconnect();


