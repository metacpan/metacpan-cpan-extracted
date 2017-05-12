use strict;

use Test::More tests => 3;
use Apache::Session::SQLite;

use DBI;
use File::Temp qw(tempdir tempfile);

my $dir = tempdir( CLEANUP => 1 );
my($fh, $filename) = tempfile( DIR => $dir );
close($fh);

my $dbh = DBI->connect("dbi:SQLite:dbname=$filename","","") or die($!);
my $sth = $dbh->do(<<'SQL');
create table sessions
( id varchar(32) not null , a_session text )
SQL
    ;

tie my %hash, 'Apache::Session::SQLite', undef, {
    DataSource => "dbi:SQLite:dbname=$filename",
} or die($!);

$hash{foo} = 'bar';
$hash{hash} = { foo => 'bar' };

my $sid = $hash{_session_id};

untie(%hash);

tie %hash, 'Apache::Session::SQLite', $sid, {
    DataSource => "dbi:SQLite:dbname=$filename",
} or die($!);

is $hash{foo},'bar','failed';
is ref($hash{hash}),'HASH' ,'failed';
is $hash{hash}->{foo},'bar','failed';

1;

