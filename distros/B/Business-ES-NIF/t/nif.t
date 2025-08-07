#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { use_ok('Business::ES::NIF') || print "Bail out!\n"; }

sub check_obj { return Business::ES::NIF->new(nif => shift); }

subtest 'Normalización de entrada' => sub {
  my %inputs = (
		'x1234567l'    => 'NIE',
		'X-1234567L'   => 'NIE',
		' 12345678-Z ' => 'NIF',
		'B-18400002'   => 'CIF',
		'Q 2826000 H'  => 'CIFe',
	       );

  plan tests => scalar(%inputs);
  
  for my $input (keys %inputs) {
    my $obj = check_obj($input);
    is($obj->type, $inputs{$input}, "Tipo correcto tras limpiar '$input'");
  }
};

subtest 'Combos' => sub {
  my @t = (
	   { nif => '12345678Z', valid => 1, type => 'NIF' },
	   { nif => '12345678A', valid => 0, type => undef },
	   { nif => 'X1234567L', valid => 1, type => 'NIE' },
	   { nif => 'Q2826000H', valid => 1, type => 'CIFe', extra => 'Organismos autónomos o instituciones religiosas' },
	  );

  plan tests => 7;

  for my $c (@t) {
    my $obj = check_obj($c->{nif});

    ok($obj->is_valid == $c->{valid},             "$c->{nif} valid => $c->{valid}");
    is($obj->type                   , $c->{type}, "Tipo correcto para $c->{nif}") if defined $c->{type};
  }
};

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

subtest 'CIF válidos - Sociedades Anónimas (A)' => sub {
  my @valid  =  qw(A12345674 A78123429);
  plan tests => scalar(@valid) * 2;
  
  for my $cif (@valid) {
    my $obj = check_obj($cif);

    ok($obj->status,        "CIF $cif es válido");
    is($obj->type  , 'CIF', "Tipo correcto para $cif");
  }
};

subtest 'CIF válidos - Sociedades Limitadas (B)' => sub {
  my @valid  =  qw(B18400002 B12345674 B78123429);
  plan tests => scalar(@valid) * 2;
  
  for my $cif (@valid) {
    my $obj = check_obj($cif);

    ok($obj->status,        "CIF $cif es válido");
    is($obj->type  , 'CIF', "Tipo correcto para $cif");
  }
};

subtest 'CIF inválidos' => sub {
  my @invalid =  qw(A12345678 B12345678 Z12345679 A1234567 A123456789 B78123427 B18400008 B78123426 Q2826000R P2826000B A1234567Q '');
  plan tests  => scalar(@invalid);

  ok(!Business::ES::NIF->new(nif => $_)->is_valid, "CIF $_ es inválido") for @invalid;
};

subtest 'CIF Provincia' => sub {
  my $Check = {
	       'B18400002' => 'Granada',
	       'B12345674' => 'Castellón',
	       'B78123429' => 'Madrid',
	       'A08123456' => 'Barcelona'
	       };

  plan tests => scalar(%{$Check});
  
  for my $Key (keys %{$Check}) {
    my $obj = check_obj($Key);

    is($obj->provincia, $Check->{$Key}, qq{CIF: $Key - Provincia: $Check->{$Key}});
  }
};

subtest 'CIFe válidos' => sub {
  my @valid  =  qw(Q2826000H P2826000H);
  plan tests => scalar(@valid) * 2;
  
  for my $cif (@valid) {
    my $obj = check_obj($cif);

    ok($obj->status,         "CIFe $cif es válido");
    is($obj->type  , 'CIFe', "Tipo correcto para $cif");
  }
};

subtest 'CIFe inválido' => sub {
  my @invalid =  qw(Q1126001H P2996009H);
  plan tests  => scalar(@invalid);

  ok(!Business::ES::NIF->new(nif => $_)->is_valid, "CIFe $_ es inválido") for @invalid;    
};

subtest 'CIFe Extra' => sub {
  my $Check = {
	       'Q2826000H' => 'Organismos autónomos o instituciones religiosas',
	       'P2826000H' => 'Corporaciones locales'
	      };
  plan tests => scalar(%{$Check});

  for my $Key (keys %{$Check}) {
    my $obj = check_obj($Key);

    is($obj->extra, $Check->{$Key}, $Key." - ".$Check->{$Key});
  }
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

subtest 'Errores descriptivos' => sub {
  my @error  =  qw(Z12345679S);
  plan tests => scalar(@error);

  for my $Check (@error) {
    my $obj = check_obj($Check);

    like($obj->error, qr/Error formato|control|inválido/i, "Mensaje de error razonable");
  }
};

subtest 'Fuzzing' => sub {
  for (1..200) {
    my $nif = sprintf("%08d", int(rand(100000000))) . substr(Business::ES::NIF::NIF_LETRAS, $_ % 23, 1);
    ok(defined Business::ES::NIF->new(nif => $nif)->is_valid, "No peta: $nif");
  }
};

done_testing();
