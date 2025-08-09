#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { use_ok('Business::ES::NIF') || print "Bail out!\n"; }

sub check_obj { return Business::ES::NIF->new(nif => shift); }

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

done_testing();
