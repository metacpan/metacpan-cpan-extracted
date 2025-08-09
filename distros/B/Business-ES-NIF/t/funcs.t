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
