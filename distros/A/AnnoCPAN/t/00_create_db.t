use strict;
use warnings;
use Test::More;
use AnnoCPAN::Config 't/config.pl';
use File::Path;
use DBI;


my $tmp_dir = 't/tmp';

# clean up
rmtree($tmp_dir);
mkdir $tmp_dir;

# read schema
open F, '<', 'tables.sqlite' or die;
my @tables = do { local $/ = ';'; <F> };
pop @tables;

#plan 'no_plan';
plan tests => 1 + @tables;

# create tables
my $dbh = DBI->connect(AnnoCPAN::Config->option('dsn')) or die $@;
for my $sql (@tables) {
    my ($name) = $sql =~ /(create.*?)\(/s;
    $dbh->do($sql) or die "Error with SQL command <<<$sql>>>:$@";
    ok(1, $name);
}

ok(-r "$tmp_dir/test.db",  "Database and tables created successfully");
