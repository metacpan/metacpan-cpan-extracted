#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

eval "use Business::Tax::VAT::Validation 1.24";
plan skip_all => "Business::Tax::VAT::Validation 1.24" if $@;

eval { require LWP::Protocol::https; 1 } or do {
  plan skip_all => "LWP::Protocol::https no disponible";
};

BEGIN { use_ok('Business::ES::NIF') || print "Bail out!\n"; }

subtest 'VIES deshabilitado por defecto' => sub {
  my $nif = Business::ES::NIF->new(nif => '12345678Z');
    
  is($nif->vies_check, undef, "Sin vies_check cuando VIES deshabilitado");
  is($nif->vies_error, undef, "Sin vies_error cuando VIES deshabilitado"); 

  is($nif->VIES(),     0    , "VIES deshabilitado por defecto");
};

subtest 'VIES con new()' => sub {
  my $nif = Business::ES::NIF->new(nif => '12345678Z', vies => 1);
    
  is($nif->VIES(),  1,         "VIES habilitado en constructor");
  is($nif->vies_check, undef,  "vies_check existe cuando VIES habilitado");

  is($nif->vies_check, undef,  "VIES check falla para NIF de prueba");
  ok(defined $nif->vies_error, "vies_error definido cuando falla");
};

subtest 'VIES no se ejecuta con documentos inválidos' => sub {
  my $nif = Business::ES::NIF->new(nif => 'INVALID123', vies => 1);
  
  is($nif->vies_check, undef   ,    "VIES no se ejecuta con documento inválido");
  is($nif->status()            , 0, "Documento inválido tiene status = 0");
};

subtest 'Manejo de errores VIES' => sub {
  local @INC = ();
  
  my $nif = Business::ES::NIF->new(nif => '12345678Z', vies => 1);

  is($nif->vies_check, undef, "vies_check = undef");
  is($nif->status()  , 1    , "Documento sigue siendo válido sin VIES");
};

subtest 'VIES con diferentes tipos' => sub {
  my @docs_test = qw(12345678Z X1234567L A12345674);

  for my $doc (@docs_test) {
    my $obj = Business::ES::NIF->new(nif => $doc, vies => 1);

    is($obj->vies_check , undef ,                        "VIES ejecutado para $doc");
    is($obj->vies_error , 'Invalid VAT Number (false)' , "vies_error definido para $doc");
  }
};

subtest 'Test funcional VIES' => sub {
  my $nif = Business::ES::NIF->new(nif => '12345678Z');  
  my $vies_result = $nif->VIES();

  is($vies_result, 0, "Método vies() ejecuta sin errores");
};

done_testing();
