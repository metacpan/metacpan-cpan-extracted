#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 8;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
  use_ok('Business::ES::NIF') || print "Bail out!\n";
}

subtest 'VIES deshabilitado por defecto' => sub {
  plan tests => 3;
    
  my $nif = Business::ES::NIF->new(nif => '12345678Z');
    
  ok(!exists $nif->{vies_check}, "Sin vies_check cuando VIES deshabilitado");
  ok(!exists $nif->{vies_error}, "Sin vies_error cuando VIES deshabilitado"); 
  is($nif->{vies}, 0, "VIES deshabilitado por defecto");
};

subtest 'VIES habilitado en constructor' => sub {
  plan tests => 4;
    
  my $nif = Business::ES::NIF->new(nif => '12345678Z', vies => 1);
    
  is($nif->{vies}, 1, "VIES habilitado en constructor");
  ok(exists $nif->{vies_check}, "vies_check existe cuando VIES habilitado");
  
  # VIES debería fallar para este NIF de prueba
  is($nif->{vies_check}, undef, "VIES check falla para NIF de prueba");
  ok(defined $nif->{vies_error}, "vies_error definido cuando falla");
};

subtest 'VIES con set()' => sub {
  plan tests => 3;
    
  my $nif = Business::ES::NIF->new();
  $nif->set('A12345674', 1);  # CIF con VIES habilitado
  
  is($nif->{vies}, 1, "VIES habilitado con set()");
  ok(exists $nif->{vies_check}, "vies_check existe");
  like($nif->{vies_error} // '', qr/./, "vies_error contiene mensaje");
};

subtest 'VIES no se ejecuta con documentos inválidos' => sub {
  plan tests => 2;
    
  my $nif = Business::ES::NIF->new(nif => 'INVALID123', vies => 1);
  
  ok(!exists $nif->{vies_check}, "VIES no se ejecuta con documento inválido");
  is($nif->{status}, 0, "Documento inválido tiene status = 0");
};

subtest 'Manejo de errores VIES' => sub {
  plan tests => 2;
  
  # Mock del caso donde Business::Tax::VAT::Validation no está disponible
  local @INC = ();  # Simular que el módulo no está disponible
  
  my $nif = Business::ES::NIF->new(nif => '12345678Z', vies => 1);
  
  # Debería manejar graciosamente la falta del módulo
  is($nif->{vies_check}, undef, "vies_check = undef");
  is($nif->{status}, 1, "Documento sigue siendo válido sin VIES");
};

subtest 'VIES con diferentes tipos' => sub {
  plan tests => 6;
  
  my @docs_test = (
		   '12345678Z',  # NIF
		   'X1234567L',  # NIE
		   'A12345674',  # CIF
		  );
  
  for my $doc (@docs_test) {
    my $obj = Business::ES::NIF->new(nif => $doc, vies => 1);
    
    # Todos deberían intentar VIES si el documento es válido
    ok(exists $obj->{vies_check}, "VIES ejecutado para $doc");
    ok(defined $obj->{vies_error}, "vies_error definido para $doc");
  }
};

subtest 'Test funcional VIES' => sub {
  plan tests => 1;
  
  # Test que el método vies() se puede llamar directamente
  my $nif = Business::ES::NIF->new(nif => '12345678Z');
  
  my $vies_result = $nif->vies();
  
  # Debería devolver 0 (no válido en VIES) pero sin errores fatales
  is($vies_result, 0, "Método vies() ejecuta sin errores");
};

done_testing();
