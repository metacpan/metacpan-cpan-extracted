use strict;
use Test::More tests => 4;

use_ok('Apache::Session::SQLite3');

use DBI;
use File::Temp qw(tempdir tempfile);

my $dir = tempdir( CLEANUP => 1 );
my($fh, $filename) = tempfile( DIR => $dir );
close($fh);

my $dbh = DBI->connect("dbi:SQLite:dbname=$filename","","") or die($!);

tie my %hash, 'Apache::Session::SQLite3', undef, {
    DataSource => "dbi:SQLite:dbname=$filename",
} or die($!);

$hash{foo} = 'bar';
$hash{hash} = { foo => 'bar' };

my $sid = $hash{_session_id};

untie(%hash);

tie %hash, 'Apache::Session::SQLite3', $sid, {
    DataSource => "dbi:SQLite:dbname=$filename",
} or die($!);

is($hash{foo}, 'bar', 'simple fetch works');
isa_ok($hash{hash}, 'HASH', 'stored reference');
is($hash{hash}{foo}, 'bar', 'multilevel fetch works');

1;
