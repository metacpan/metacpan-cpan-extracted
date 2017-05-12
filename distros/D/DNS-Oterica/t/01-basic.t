#!/icg/bin/perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

BEGIN {
  $ENV{DNSO_TESTING_PLUGINS} = join q{,}, qw(
    DNS::Oterica::NodeFamily::ExampleAliasDomain
    DNS::Oterica::NodeFamily::ExampleArchiver
    DNS::Oterica::NodeFamily::ExampleDomain
    DNS::Oterica::NodeFamily::ExampleMX
    DNS::Oterica::NodeFamily::ExampleNS
    DNS::Oterica::NodeFamily::ExampleVDom
    DNS::Oterica::NodeFamily::ExampleWWW
    DNS::Oterica::NodeFamily::Jeeves
    DNS::Oterica::NodeFamily::PostLink
  );
}

use DNS::Oterica;
use DNS::Oterica::App;
use DNS::Oterica::Test;

my $dnso_root = 'eg';
my $dnso = new_ok 'DNS::Oterica::App', [ {
  root       => 'eg',
  hub_args   => {
    ns_family  => 'com.example.ns',
    hostmaster => 'hostmast@example.com',
  },
} ];

$dnso->populate_networks;
$dnso->populate_domains;
$dnso->populate_hosts;

my @networks = map { $_->as_data_lines } $dnso->hub->networks;
my @nodes = map { $_->as_data_lines } $dnso->hub->nodes;
my @node_families = map { $_->as_data_lines } $dnso->hub->node_families;

DNS::Oterica::Test->collect_dnso_nodes(@nodes);
DNS::Oterica::Test->collect_dnso_node_families(@node_families);

my $records = DNS::Oterica::Test->records;
ok(ref $records eq 'HASH', '$records is a hashref');

my @hosts = map { s[eg/hosts/][]; "$_.example.com" } glob 'eg/hosts/*';
my @domains = qw/lists.codesimply.com example.com foobox.com/;

ok(exists $records->{$_}{'+'}, "$_ has a + record") for @hosts;
ok(exists $records->{$_}{'Z'}, "$_ has a Z record") for @domains;

is_deeply(
  [ sort @networks ],
  [
    "%FB:\n",
    "%mc:10.1\n",
    "%mp:10.2.0\n",
  ],
  "location lines are as expected",
);

subtest "per-location IPs" => sub {
  my @azure_lines  = grep {; /\A\+azure/ } @nodes;
  my @world_lines  = grep {; /:FB$/ } @azure_lines;
  my @micro_lines  = grep {; /:mp$/ } @azure_lines;
  my @always_lines = grep {; /:$/   } @azure_lines;

  is(@azure_lines, 3, "azure has 2 IPs");
  is(@world_lines, 1, "one is a world IP");
  is(@micro_lines, 1, "one is a microport IP");
  is(@always_lines, 1, "one is always visible");

  like($world_lines[0],  qr/10\.20\.0\.100/, "the non-world is 10.20.0.100");
  like($micro_lines[0],  qr/10\.2\.0\.2/,    "the microport is 10.2.0.2");
  like($always_lines[0], qr/10\.99\.88\.77/, "the omnipresent is 10.99.88.77");
};

subtest "stupid cidr rdns hack" => sub {
  my @ptr_lines = grep {; /\A\^/ } @nodes;

  ok(
    ! (grep { /0-24/ } @ptr_lines),
    "no 0-24 delegation on 10.* addrs",
  );
};

subtest "tinydns checks" => sub {
  my @lines = DNS::Oterica::RecordMaker::TinyDNS->srv({
    service   => 'imaps',
    protocol  => '993',
    domain    => 'example.com',
    priority  => 12,
    weight    => 60000,
    target    => 'imap.example.com',
    port      => 993,
    location  => 'lo',
  });

  is(@lines, 1, "we get one SRV record");
  is(
    $lines[0],
    ':_imaps._993.example.com:33:\000\014\352\140\003\341\004imap\007example\003com\000:1800:lo' . "\n",
    "...and it is just what we expect",
  );

  my $ok = eval {
    DNS::Oterica::RecordMaker::TinyDNS->srv({
      service   => 'imaps',
      protocol  => '993',
      domain    => 'example.com',
      priority  => 12,
      weight    => 60000,
      # target    => 'imap.example.com',
      port      => 993,
      location  => 'lo',
    });
  };

  my $error = $@;
  ok(! $ok, "can't make a record without a target");
  like($error, qr/no target/, "...error says so");
};


done_testing;
