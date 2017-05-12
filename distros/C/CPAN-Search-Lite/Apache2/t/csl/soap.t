#!/usr/bin/perl
use strict;
use warnings;
use Apache::Test;
use Apache::TestUtil qw(t_cmp t_write_perl_script);
use Apache::TestRequest qw(GET);
use CPAN::DistnameInfo;
use FindBin;
use lib "$FindBin::Bin/../lib";
use TestCSL qw($expected make_soap download load_cs has_data $ppm_packs);
use File::Spec::Functions;

use Cwd;
my $cwd = getcwd;
my $CPAN = catdir $cwd, '../lib/t/cpan';

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';

plan tests => 90;

my $soap_uri = "http://$hostport/Apache2/CPAN/SOAP";
my $soap_proxy = "http://$hostport/soap";
my $soap = make_soap($soap_uri, $soap_proxy) or die "SOAP::Lite setup failed";
ok t_cmp(defined $soap, 1);

my ($results, $query, $fields, $dist, $module);

for my $id (keys %$expected) {
    $fields = [qw(cpanid fullname email)];
    $query = $soap->query(mode => 'author', name => $id, 
                          fields => $fields);
    eval{$query->fault};
    ok t_cmp($@, "");
    ok t_cmp($query->fault, undef);
    $results = $query->result();
    ok t_cmp(defined $results, 1);
    ok t_cmp($results->{cpanid}, $id);
    ok t_cmp($results->{fullname}, $expected->{$id}->{fullname});
    ok t_cmp(defined $results->{email}, 1);

    $dist = $expected->{$id}->{dist};
#    $fields = [qw(dist_name dist_abs dist_vers cpanid 
#                  md5 dist_file size birth)];
    $query = $soap->query(mode => 'dist', name => $dist);
    eval{$query->fault};
    ok t_cmp($@, "");
    ok t_cmp($query->fault, undef);
    $results = $query->result();
    ok t_cmp(defined $results, 1);
    ok t_cmp($results->{dist_name}, $dist);
    my $dist_file = $results->{dist_file};
    ok t_cmp($dist_file, qr{^$dist});
    ok t_cmp($results->{cpanid}, $id);
    my $download = download($id, $dist_file);
    my $d = CPAN::DistnameInfo->new($download);
    ok t_cmp($results->{dist_vers}, $d->version);
    ok t_cmp(defined $results->{size}, 1);
    ok t_cmp(defined $results->{birth}, 1);
    my $cs = catfile $CPAN, download($id, 'CHECKSUMS');
    my $cksum = load_cs($cs);
    ok t_cmp($results->{md5}, $cksum->{$dist_file}->{md5});

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
    $fields = [qw(mod_name mod_abs mod_vers dist_name cpanid dist_file)];
    $query = $soap->query(mode => 'module', name => $module, 
                          fields => $fields);
    eval{$query->fault};
    ok t_cmp($@, "");
    ok t_cmp($query->fault, undef);
    $results = $query->result();
    ok t_cmp(defined $results, 1);
    ok t_cmp($results->{mod_name}, $module);
    ok t_cmp($results->{dist_name}, $dist);
    ok t_cmp($results->{dist_file}, qr{^$dist});
    ok t_cmp(defined $results->{mod_vers}, 1);
    ok t_cmp(defined $results->{mod_abs}, 1);
}

my $no_such = 'ZZZ';

$fields = [qw(cpanid fullname email)];
$query = $soap->query(mode => 'author', name => $no_such, 
                      fields => $fields);
eval{$query->fault};
ok t_cmp($@, "");
ok t_cmp($query->fault, undef);
$results = $query->result();
ok t_cmp($results, undef);

$fields = [qw(dist_name dist_abs dist_vers cpanid dist_file size birth)];
$query = $soap->query(mode => 'dist', name => $no_such, 
                      fields => $fields);
eval{$query->fault};
ok t_cmp($@, "");
ok t_cmp($query->fault, undef);
$results = $query->result();
ok t_cmp($results, undef);

$fields = [qw(mod_name mod_abs mod_vers dist_name cpanid dist_file)];
$query = $soap->query(mode => 'module', name => $no_such, 
                      fields => $fields);
eval{$query->fault};
ok t_cmp($@, "");
ok t_cmp($query->fault, undef);
$results = $query->result();
ok t_cmp($results, undef);
