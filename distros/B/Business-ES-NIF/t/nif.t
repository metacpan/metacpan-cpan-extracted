#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
  use_ok('Business::ES::NIF') || print "Bail out!\n";
}

diag("Testing Business::ES::NIF $Business::ES::NIF::VERSION, Perl $], $^X");

subtest 'NIF' => sub {
  my @valid = (
	       '01234567L',
	       '12345678Z',
	       '78342800Q',
	       '87654321X', 
	       '11111111H', 
	       '22222222J'
	      );

  plan tests => scalar(@valid) * 2;
  
  for my $nif (@valid) {
    my $obj = Business::ES::NIF->new(nif => $nif);
    ok($obj->{status}, "NIF $nif es válido");
    is($obj->{type}, 'NIF', "Tipo correcto para $nif");
  }
};

subtest 'NIF inválidos' => sub {
  my @invalid = (
		 '12345678A',
		 '87654321B',  
		 '1234567Z',   
		 '123456789Z', 
		 'ABCDEFGHZ',  
		 ''
		);

  plan tests => scalar(@invalid);
  
  for my $nif (@invalid) {
    my $obj = Business::ES::NIF->new(nif => $nif);
    ok(!$obj->{status}, "NIF $nif es inválido");
  }
};

subtest 'NIE Válidos' => sub {
  my @valid = (
	       'X1234567L',
	       'X0000000T',
	       'X9999999J',
	       'Y1234567X',
	       'Y0000000Z',
	       'Y9999999G',
	       'Z1234567R',
	       'Z0000000M',
	       'Z9999999H'
	      );

  plan tests => scalar(@valid) * 2;
  
  for my $nie (@valid) {
    my $obj = Business::ES::NIF->new(nif => $nie);
    ok($obj->{status}, "NIE $nie es válido");
    is($obj->{type}, 'NIE', "Tipo correcto para $nie");
  }
};

subtest 'NIE inválidos' => sub {
  my @invalid = (
		 'X1234567A',
		 'Y1234567B',
		 'Z1234567C',
		 'W1234567L',
		 'X123456L'  
		);

  plan tests => scalar(@invalid);
    
  for my $nie (@invalid) {
    my $obj = Business::ES::NIF->new(nif => $nie);
    ok(!$obj->{status}, "NIE $nie es inválido");
  }
};

subtest 'CIF válidos - Sociedades Anónimas (A)' => sub {
  my @valid = (
	       'A12345674',
	       'A78123429'
	      );
  
  plan tests => scalar(@valid) * 2;
  
  for my $cif (@valid) {
    my $obj = Business::ES::NIF->new(nif => $cif);
    ok($obj->{status}, "CIF $cif es válido");
    is($obj->{type}, 'CIF', "Tipo correcto para $cif");
  }
};

subtest 'CIF válidos - Sociedades Limitadas (B)' => sub {
  my @valid = (
	       'B18400002',
	       'B12345674',
	       'B78123429'
	      );

  plan tests => scalar(@valid) * 2;
  
  for my $cif (@valid) {
    my $obj = Business::ES::NIF->new(nif => $cif);
    ok($obj->{status}, "CIF $cif es válido");
    is($obj->{type}, 'CIF', "Tipo correcto para $cif");
  }
};

subtest 'CIF Provincia' => sub {
  my $obj;
  
  $obj = Business::ES::NIF->new(nif => 'B18400002');
  is($obj->{provincia},'Granada','CIF Provincia: Granada');

  $obj = Business::ES::NIF->new(nif => 'B12345674');
  is($obj->{provincia},'Castellón','CIF Provincia: Castellón');

  $obj = Business::ES::NIF->new(nif => 'B78123429');
  is($obj->{provincia},'Madrid','CIF Provincia: Madrid');

  $obj = Business::ES::NIF->new(nif => 'A08123456');
  is($obj->{provincia},'Barcelona','CIF Provincia: Barcelona');
};

subtest 'CIFe válidos - Entidades especiales' => sub {
  my @valid = (
	       'Q2826000H',
	       'P2826000H'
	      );
  
  plan tests => scalar(@valid) * 2;
  
  for my $cif (@valid) {
    my $obj = Business::ES::NIF->new(nif => $cif);
    ok($obj->{status}, "CIFe $cif es válido");
    is($obj->{type}, 'CIFe', "Tipo correcto para $cif");
  }
};

subtest 'CIF inválidos' => sub {
  my @invalid = (
		 'A12345678', 
		 'B12345678', 
		 'Z12345679', 
		 'A1234567',  
		 'A123456789',
		 'B78123427',
		 'B18400008',
		 'B78123426',
		 'Q2826000R',
		 'P2826000B',
		 ''
		);

  plan tests => scalar(@invalid);
  
  for my $cif (@invalid) {
    my $obj = Business::ES::NIF->new(nif => $cif);
    ok(!$obj->{status}, "CIF $cif es inválido");
  }
};

done_testing();
