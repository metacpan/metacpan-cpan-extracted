#!/usr/bin/perl

# Copyright (c) 2013 DCIT, a.s. [http://www.dcit.cz] - Miko

use strict;
use warnings;
use Mojo::UserAgent;
use Crypt::SRP;

my $base_url = 'http://127.0.0.1:3000';
my $ua = Mojo::UserAgent->new;
#$ua->http_proxy('http://127.0.0.1:8081');

my $fmt = 'hex'; # all SRP related parameters are automatically converted from/to hex

my @test_set = ( ['alice', 'password123'] );
push @test_set, ["user$_", "secret$_"] for (1..3);

for (@test_set) {
  my $I = $_->[0];
  my $P = $_->[1];

  warn "#####################\n";
  warn "# [login=$I] SRP step1\n";

  my $cli = Crypt::SRP->new('RFC5054-1024bit', 'SHA1', $fmt);

  #$cli->{predefined_a} = Math::BigInt->from_hex('60975527035CF2AD1989806F0407210BC81EDC04E2762A56AFD529DDDA2D4393'); #DEBUG-ONLY
  my ($A, $a) = $cli->client_compute_A(32);
  warn "I = $I\n";
  warn "P = $P\n";
  warn "A = ", substr($A,0,30), "..\n";
  warn "a = ", substr($a,0,30), "..\n";
  warn ">> gonna send request 1\n\n";
  my $tx1 = $ua->post("$base_url/auth/srp_step1" => json => {I=>$I, A=>$A});
  $tx1->res->json or warn("invalid response") and next;

  warn "# [login=$I] SRP step2\n";

  my $s = $tx1->res->json->{s};
  my $B = $tx1->res->json->{B};  
  my $token = $tx1->res->json->{token};
  $cli->client_verify_B($B) or warn("invalid B") and next;
  $cli->client_init($I, $P, $s);
  my $M1 = $cli->client_compute_M1();
  warn "token = $token\n";
  warn "s = $s\n";
  warn "B = ", substr($B,0,30), "..\n";
  warn "M1= $M1\n";
  warn ">> gonna send request 2\n\n";
  my $tx2 = $ua->post("$base_url/auth/srp_step2" => json => {M1=>$M1, token=>$token});
  $tx2->res->json or warn("invalid response") and next;

  warn "# [login=$I] SRP result\n";

  my $M2 = $tx2->res->json->{M2};
  warn "M2= $M2\n" if $M2;
  if ($M2 && $cli->client_verify_M2($M2)) {
     my $K = $cli->get_secret_K(); # shared secret
     warn "[SUCCESS] K = $K\n\n";
   }
   else {
     warn "[ERROR]\n\n";
   }
 }