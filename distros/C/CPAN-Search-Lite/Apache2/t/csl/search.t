#!/usr/bin/perl
use strict;
use warnings;
use Apache::Test;
use Apache::TestUtil qw(t_cmp);
use Apache::TestRequest qw(GET);
use FindBin;
use lib "$FindBin::Bin/../lib";
use TestCSL qw($expected make_soap $ppm_packs has_data);

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';

plan tests => 87;

my $soap_uri = "http://$hostport/TestCSL/search";
my $soap_proxy = "http://$hostport/TestCSL__search";
my $soap = make_soap($soap_uri, $soap_proxy) or die "SOAP::Lite setup failed";
ok t_cmp(defined $soap, 1);

my ($results, $search, $dist, $module);

for my $id (keys %$expected) {
    $search = $soap->search(mode => 'author', query => "^$id\$");
    eval{$search->fault};
    ok t_cmp($@, "");
    ok t_cmp($search->fault, undef);
    $results = $search->result();
    ok t_cmp(defined $results, 1);
    ok t_cmp(ref($results), 'HASH');
    ok t_cmp($results->{cpanid}, $id);
    ok t_cmp($results->{fullname}, $expected->{$id}->{fullname});

    $dist = $expected->{$id}->{dist};
    $search = $soap->search(mode => 'dist', query => "^$dist\$");
    eval{$search->fault};
    ok t_cmp($@, "");
    ok t_cmp($search->fault, undef);
    $results = $search->result();
    ok t_cmp(defined $results, 1);
    ok t_cmp(ref($results), 'HASH', $dist);
    ok t_cmp($results->{dist_name}, $dist, "Searching for $dist");

    my $ppm = $results->{ppms};
    my $ppm_info = $ppm_packs->{$dist};
    if (has_data($ppm_info) ) {
      ok t_cmp(ref($ppm), 'ARRAY');
      ok t_cmp(scalar @$ppm, 1);
      foreach my $key(keys %$ppm_info) {
	ok t_cmp($ppm->[0]->{$key}, $ppm_info->{$key});
      }
    }

    $module = $expected->{$id}->{mod};
    $search = $soap->search(mode => 'module', query => "^$module\$");
    eval{$search->fault};
    ok t_cmp($@, "");
    ok t_cmp($search->fault, undef);
    $results = $search->result();
    ok t_cmp(defined $results, 1);
    ok t_cmp(ref($results), 'HASH');
    ok t_cmp($results->{mod_name}, $module);
    ok t_cmp($results->{dist_name}, $dist);
}

my $no_such = 'ZZZ';
for my $mode(qw(author dist module)) {
    $search = $soap->search(mode => $mode, query => $no_such);
    eval{$search->fault};
    ok t_cmp($@, "");
    ok t_cmp($search->fault, undef);
    $results = $search->result();
    ok t_cmp($results, undef);
}

my %hits;

$search = $soap->search(mode => 'author', query => "GSA");
eval{$search->fault};
ok t_cmp($@, "");
ok t_cmp($search->fault, undef);
$results = $search->result();
ok t_cmp(defined $results, 1);
ok t_cmp(ref($results), 'ARRAY');
ok t_cmp(@$results, 2);
$hits{$_->{cpanid}}++ for @$results;
ok t_cmp($hits{GSAR}, 1, "testing for GSAR");

%hits = ();
$search = $soap->search(mode => 'module', query => "NET");
eval{$search->fault};
ok t_cmp($@, "");
ok t_cmp($search->fault, undef);
$results = $search->result();
ok t_cmp(defined $results, 1);
ok t_cmp(ref($results), 'ARRAY');
ok t_cmp(@$results, 80);
$hits{$_->{mod_name}}++ for @$results;
ok t_cmp($hits{'Net::FTP'}, 1, "testing for Net::FTP");

%hits = ();
$search = $soap->search(mode => 'dist', query => "lib");
eval{$search->fault};
ok t_cmp($@, "");
ok t_cmp($search->fault, undef);
$results = $search->result();
ok t_cmp(defined $results, 1);
ok t_cmp(ref($results), 'ARRAY');
ok t_cmp(@$results, 9);
$hits{$_->{dist_name}}++ for @$results;
ok t_cmp($hits{'libnet'}, 1, "testing for libnet");



