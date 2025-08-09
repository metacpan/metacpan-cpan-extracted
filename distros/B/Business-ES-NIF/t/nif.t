#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { use_ok('Business::ES::NIF') || print "Bail out!\n"; }

sub check_obj { return Business::ES::NIF->new(nif => shift); }

subtest 'NIF' => sub {
  my @valid  =  qw(01234567L 12345678Z 78342800Q 87654321X 11111111H 22222222J);
  plan tests => scalar(@valid) * 2;
  
  for my $nif (@valid) {
    my $obj = check_obj($nif);

    ok($obj->status,        "NIF $nif es válido");
    is($obj->type  , 'NIF', "Tipo correcto para $nif");
  }
};

subtest 'NIF inválidos' => sub {
  my @invalid =  qw(12345678A 87654321B 1234567Z 123456789Z ABCDEFGHZ '');
  plan tests  => scalar(@invalid);
  
  ok(!Business::ES::NIF->new(nif => $_)->is_valid, "NIF $_ es inválido") for @invalid;
};

subtest 'NIE Válidos' => sub {
  my @valid  =  qw(X1234567L X0000000T X9999999J Y1234567X Y0000000Z Y9999999G Z1234567R Z0000000M Z9999999H);
  plan tests => scalar(@valid) * 2;
  
  for my $nie (@valid) {
    my $obj = check_obj($nie);

    ok($obj->status,        "NIE $nie es válido");
    is($obj->type  , 'NIE', "Tipo correcto para $nie");
  }
};

subtest 'NIE inválidos' => sub {
  my @invalid =  qw(X1234567A Y1234567B Z1234567C W1234567L X123456L);
  plan tests  => scalar(@invalid);

  ok(!Business::ES::NIF->new(nif => $_)->is_valid, "NIE $_ es inválido") for @invalid;
};

subtest 'NIFe válidos (K, L, M)' => sub {
  my @valid  =  qw(K1234567L L2345678T M3456789G);
  plan tests => scalar(@valid) * 2;

  for my $nif (@valid) {
    my $obj = Business::ES::NIF->new(nif => $nif);

    ok($obj->is_valid,         "NIFe $nif es válido");
    is($obj->type    , 'NIFe', "Tipo correcto para $nif");
  }
};

subtest 'NIFe inválidos' => sub {
  my @invalid =  qw(K1234567A L0000000Z M1111111Q K123456 M12345678);
  plan tests  => scalar(@invalid);

  ok(!Business::ES::NIF->new(nif => $_)->is_valid, "NIFe $_ es inválido") for @invalid;
};

subtest 'NIFe inválidos' => sub {
  my @invalid =  qw(M1234567A M123456 M12345678 MABCDEFGH);
  plan tests  => scalar(@invalid);

  ok(!Business::ES::NIF->new(nif => $_)->is_valid, "NIFe $_ es inválido") for @invalid;
};

done_testing();
