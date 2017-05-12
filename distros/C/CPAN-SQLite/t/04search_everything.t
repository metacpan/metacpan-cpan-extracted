# $Id: 04search_everything.t 44 2014-11-22 08:15:20Z stro $

use strict;
use warnings;
use Test::More;
use Cwd;
use CPAN::SQLite::Search;
use FindBin;
use File::Spec::Functions;
use lib "$FindBin::Bin/lib";
use TestSQL qw($dists $mods $auths vcmp);
use CPAN::SQLite::DBI::Search;
use CPAN::SQLite::DBI qw($dbh);

my $cwd = getcwd;
my $CPAN = catfile $cwd, 't', 'cpan';

plan tests => 14;
my $db_name = 'cpandb.sql';
my $db_dir = $cwd;

my $cdbi = CPAN::SQLite::DBI::Search->new(db_name => $db_name,
                                          db_dir => $db_dir);

my $query = CPAN::SQLite::Search->new(db_name => $db_name,
                                      db_dir => $db_dir);
ok(defined $query);
isa_ok($query, 'CPAN::SQLite::Search');

my $results;

my $everything = q{.};
my $all_res_qty = { 'author' => 4, 'dist' => 92, 'module' => 544, };
for my $mode (qw(author dist module)) {
  {
    my $type = 'name';
    $query->query(mode => $mode, $type => $everything);
    $results = $query->{results};
    ok(not defined $results);
  }
  {
    my $type = 'query';
    $query->query(mode => $mode, $type => $everything);
    $results = $query->{results};
    ok(defined $results);
    isa_ok($results, 'ARRAY');
    is(scalar @{$results}, $all_res_qty->{$mode}, 'Correct number of query results');
  }
}
