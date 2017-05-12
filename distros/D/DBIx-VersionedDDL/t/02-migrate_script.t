#!perl
use strict;
use warnings;
use Test::More tests => 2;
use FindBin qw($Bin);
use DBI;

my $script = "$Bin/../script/migrate_schema";

unless (-d "$Bin/data") {
    mkdir "$Bin/data" || die $!;
}
my $db_file = "$Bin/data/dbiv.db";
unlink $db_file if -f $db_file;

system("$^X $script --dsn=dbi:SQLite:$db_file --ddl_dir=$Bin/ddl_dir_slash --separator=/");

my $dbh = DBI->connect("dbi:SQLite:$db_file", "", "");

my $version_rec = {
    'status'  => 'success',
    'version' => '3',
    'message' => undef,
};

my $version = $dbh->selectrow_hashref('select * from schema_version');
is_deeply($version, $version_rec, 'Migrate script');
$dbh->disconnect;

unlink $db_file;

system("$^X $script --dsn=dbi:SQLite:$db_file --ddl_dir=$Bin/ddl_dir_slash --separator=/ --version=2");

$dbh = DBI->connect("dbi:SQLite:$db_file", "", "");

$version_rec = {
    'status'  => 'success',
    'version' => '2',
    'message' => undef,
};

$version = $dbh->selectrow_hashref('select * from schema_version');
is_deeply($version, $version_rec, 'Migrate script - exact version');
$dbh->disconnect;

unlink $db_file;

rmdir "$Bin/data";
