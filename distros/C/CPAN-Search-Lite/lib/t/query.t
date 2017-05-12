#!/usr/bin/perl
use strict;
use warnings;
use Test;
use Cwd;
use CPAN::Search::Lite::Query;
use FindBin;
use File::Spec::Functions;
use lib "$FindBin::Bin/../../Apache2/t/lib";
use TestCSL qw($expected download load_cs %has_doc $has_prereqs);
use CPAN::Search::Lite::DBI::Query;
use CPAN::Search::Lite::DBI qw($dbh);

my $cwd = getcwd;
my $CPAN = catfile $cwd, 't', 'cpan';

plan tests => 83;

my ($db, $user, $passwd, $max_results) = ('test', 'test', '', 200);
my $cdbi = CPAN::Search::Lite::DBI::Query->new(db => $db,
                                              user => $user,
                                              passwd => $passwd);

my $sql = qq{SELECT src,doc from mods WHERE mod_name=?};
my $sth = $dbh->prepare($sql);

foreach my $mod(keys %has_doc) {
    $sth->execute($mod);
    while( my ($src,$doc) = $sth->fetchrow_array) {
        ok($src, 1);
        ok($doc, $has_doc{$mod});
    }
}
$sth->finish;

$sql = qq{SELECT mod_name,req_vers from dists,mods,reqs } .
  qq{WHERE dists.dist_name=? } .
  qq{AND (dists.dist_id=reqs.dist_id) } .
  qq{AND (reqs.mod_id=mods.mod_id)};
$sth = $dbh->prepare($sql);

foreach my $dist(keys %$has_prereqs) {
  $sth->execute($dist);
  while( my ($mod_name,$req_vers) = $sth->fetchrow_array) {
    ok(defined $mod_name, exists $has_prereqs->{$dist}->{$mod_name});
    ok($req_vers+0, $has_prereqs->{$dist}->{$mod_name}+0);
  }
}
$sth->finish;

my $query = CPAN::Search::Lite::Query->new(db => $db,
                                           user => $user,
                                           passwd => $passwd,
                                           max_results => $max_results);
ok(defined $query);
ok(ref($query) eq 'CPAN::Search::Lite::Query');

my ($results, $fields, $dist, $module);

for my $id (keys %$expected) {
    $fields = [qw(cpanid fullname email)];
    $query->query(mode => 'author', name => $id, fields => $fields);
    $results = $query->{results};
    ok(defined $results);
    ok($results->{cpanid}, $id);
    ok($results->{fullname}, $expected->{$id}->{fullname});
    ok(defined $results->{email});

    $dist = $expected->{$id}->{dist};
    $fields = [qw(dist_name dist_abs dist_vers cpanid dist_file size birth md5)];
    $query->query(mode => 'dist', name => $dist, fields => $fields);
    $results = $query->{results};
    ok(defined $results);
    ok($results->{dist_name}, $dist);
    my $filename = $results->{dist_file};
    ok($filename, qr{^$dist});
    ok($results->{cpanid}, $id);
    ok($results->{dist_vers} > 0);
    ok(defined $results->{size});
    ok(defined $results->{birth});
    my $cs = catfile $CPAN, download($id, 'CHECKSUMS');
    my $cksum = load_cs($cs);
    ok($results->{md5}, $cksum->{$filename}->{md5});

    $module = $expected->{$id}->{mod};
    $fields = [qw(mod_name mod_abs mod_vers dist_name cpanid dist_file)];
    $query->query(mode => 'module', name => $module, fields => $fields);
    $results = $query->{results};
    ok(defined $results);
    ok($results->{mod_name}, $module);
    ok($results->{dist_name}, $dist);
    ok($results->{dist_file}, qr{^$dist});
    ok(defined $results->{mod_vers});
    ok(defined $results->{mod_abs});
}

my $no_such = 'ZZZ';

$fields = [qw(cpanid fullname email)];
$query->query(mode => 'author', name => $no_such, fields => $fields);
$results = $query->{results};
ok(not defined $results);

$fields = [qw(dist_name dist_abs dist_vers cpanid dist_file size birth)];
$query->query(mode => 'dist', name => $no_such, fields => $fields);
$results = $query->{results};
ok(not defined $results);

$fields = [qw(mod_name mod_abs mod_vers dist_name cpanid dist_file)];
$query->query(mode => 'module', name => $no_such, fields => $fields);
$results = $query->{results};
ok(not defined $results);


