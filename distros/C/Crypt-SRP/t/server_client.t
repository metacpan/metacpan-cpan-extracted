use strict;
use warnings;

use Test::More;
use Crypt::SRP;

$ENV{MOJO_LOG_LEVEL} = 'warn';
plan skip_all => "Test::Mojo not installed" unless eval { require Test::Mojo } ;
plan skip_all => "Mojolicious 3.93+ required" if eval { require Mojolicious; $Mojolicious::VERSION } < 3.93;
plan tests => 16;

require './examples/srp_server.pl';

my $t = Test::Mojo->new;
my $base_url = '';
my $ua = $t->ua;
my $fmt = 'hex'; # all SRP related parameters are automatically converted from/to hex

my @test_set = ( ['alice', 'password123'] );
push @test_set, ["user$_", "secret$_"] for (1..3);

for (@test_set) {
  my $I = $_->[0];
  my $P = $_->[1];

  my $cli = Crypt::SRP->new('RFC5054-1024bit', 'SHA1', $fmt);
  #$cli->{predefined_a} = Math::BigInt->from_hex('60975527035CF2AD1989806F0407210BC81EDC04E2762A56AFD529DDDA2D4393'); #DEBUG-ONLY
  my ($A, $a) = $cli->client_compute_A(32);
  my $tx1 = $ua->post("$base_url/auth/srp_step1" => json => {I=>$I, A=>$A});
  ok($tx1->res->json, "invalid response 1");

  my $s = $tx1->res->json->{s};
  my $B = $tx1->res->json->{B};
  my $token = $tx1->res->json->{token};
  ok($cli->client_verify_B($B), "[$I] invalid B");
  $cli->client_init($I, $P, $s);
  my $M1 = $cli->client_compute_M1();
  my $tx2 = $ua->post("$base_url/auth/srp_step2" => json => {M1=>$M1, token=>$token});
  ok($tx2->res->json, "[$I] invalid response 2");

  my $M2 = $tx2->res->json->{M2};
  my $K;
  if ($M2 && $cli->client_verify_M2($M2)) {
    $K = $cli->get_secret_K(); # shared secret
  }
  ok($K, "[$I] shared secret");
 }
