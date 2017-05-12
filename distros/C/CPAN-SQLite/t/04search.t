# $Id: 04search.t 31 2011-06-12 22:56:18Z stro $

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

plan tests => 2668;
my $db_name = 'cpandb.sql';
my $db_dir = $cwd;

my $cdbi = CPAN::SQLite::DBI::Search->new(db_name => $db_name,
                                          db_dir => $db_dir);

my $query = CPAN::SQLite::Search->new(db_name => $db_name,
                                      db_dir => $db_dir);
ok(defined $query);
isa_ok($query, 'CPAN::SQLite::Search');

my $results;

for my $cpanid (keys %$auths) {
  $query->query(mode => 'author', name => $cpanid);
  $results = $query->{results};
  ok(defined $results);
  is($results->{cpanid}, $cpanid);
  for (qw(fullname email)) {
    is($results->{$_}, $auths->{$cpanid}->{$_});
  }
}

for my $dist_name(keys %$dists) {
  $query->query(mode => 'dist', name => $dist_name);
  $results = $query->{results};
  ok(defined $results);
  is($results->{dist_name}, $dist_name);
  foreach (qw(dist_file dist_abs dist_dslip cpanid)) {
    next unless $dists->{$dist_name}->{$_};
    is($results->{$_}, $dists->{$dist_name}->{$_});
  }
  next unless $dists->{$dist_name}->{dist_vers};
  is(vcmp($results->{dist_vers}, $dists->{$dist_name}->{dist_vers}), 0);
}

foreach my $mod_name (keys %$mods) {
  $query->query(mode => 'module', name => $mod_name);
  $results = $query->{results};
  ok(defined $results);
  is($results->{mod_name}, $mod_name);
  foreach (qw(mod_abs chapterid dist_name dslip)) {
    next unless $mods->{$mod_name}->{$_};
    is($results->{$_}, $mods->{$mod_name}->{$_});
  }
  next unless $mods->{$mod_name}->{mod_vers};
  is(vcmp($results->{mod_vers}, $mods->{$mod_name}->{mod_vers}), 0);
}

my %keys = map {$_ => 1} qw(email fullname);
for my $auth_search (qw(G G\w+A)) {
  my $auth_searches = [];
  for my $cpanid (keys %$auths) {
    next unless ($cpanid =~ /$auth_search/i
      or $auths->{$cpanid}->{fullname} =~ /$auth_search/i);
    push @$auth_searches, {cpanid => $cpanid, %{$auths->{$cpanid}}};
  }
  $query->query(mode => 'author', query => $auth_search);
  $results = $query->{results};
  ok(defined $results);
  isa_ok($results, 'ARRAY');
  is(scalar @$results, scalar @$auth_searches);
  compare_arrays($results, $auth_searches, \%keys);
}

%keys = map {$_ => 1} qw(dist_vers cpanid dist_file);
for my $dist_search(qw(apache test.*perl)) {
  my $dist_searches = [];
  for my $dist_name (keys %$dists) {
    next unless $dist_name =~ /$dist_search/i;
    push @$dist_searches, {dist_name => $dist_name, %{$dists->{$dist_name}}};
  }
  $query->query(mode => 'dist', query => $dist_search);
  $results = $query->{results};
  ok(defined $results);
  isa_ok($results, 'ARRAY');
  is(scalar @$results, scalar @$dist_searches);
  compare_arrays($results, $dist_searches, \%keys);
}

%keys = map {$_ => 1}  qw(dist_name mod_vers);
for my $mod_search (qw(net ^uri::.*da)) {
  my $mod_searches = [];
  for my $mod_name (keys %$mods) {
    next unless $mod_name =~ /$mod_search/i;
    push @$mod_searches, {mod_name => $mod_name, %{$mods->{$mod_name}}};
  }
  $query->query(mode => 'module', query => $mod_search);
  $results = $query->{results};
  ok(defined $results);
  isa_ok($results, 'ARRAY');
  is(scalar @$results, scalar @$mod_searches);
  compare_arrays($results, $mod_searches, \%keys);
}

my $no_such = 'ZZZ';
for my $mode (qw(author dist module)) {
  for my $type (qw(name query)) {
    $query->query(mode => $mode, $type => $no_such);
    $results = $query->{results};
    ok(not defined $results);
  }
}

# compare two array of hashes, disregarding order, with the
# hashes having the same keys
# the first argument is what's received, the 2nd what's expected
# and the third the expected keys that should match
sub compare_arrays {
  my ($x, $y, $keys) = @_;
  my $N = scalar @$x;
  for (my $i=0; $i<$N; $i++) {
    my $href = $x->[$i];
    for my $key( keys %$href) {
      next unless defined $keys->{$key};
      next unless $x->[$i]->{$key};
      my $flag = 0;
      for (my $j=0; $j<$N; $j++) {
        if ($y->[$j]->{$key}) {
          my $test = ($key =~ /vers$/) ?
            (vcmp($x->[$i]->{$key}, $y->[$j]->{$key}) == 0) :
              $x->[$i]->{$key} eq $y->[$j]->{$key};
          if ($test) {
            pass("Found matching $key");
            $flag++;
            last;
          }
        }
      }
      unless ($flag) {
        fail(qq{Matching $key not found});
      }
    }
  }
}

