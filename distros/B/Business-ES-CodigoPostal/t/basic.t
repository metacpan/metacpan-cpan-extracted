#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Business::ES::CodigoPostal 'validate_cp';

BEGIN { use_ok('Business::ES::CodigoPostal') }

{
  my $r1 = validate_cp('01000');
  ok($r1->{valid}, 'Límite inferior exacto: 01000');
    
  my $r2 = validate_cp('52999'); 
  ok($r2->{valid}, 'Límite superior exacto: 52999');

  my $r3 = validate_cp('00999');
  ok(!$r3->{valid}, 'Justo por debajo del límite');
  
  my $r4 = validate_cp('53000');
  ok(!$r4->{valid}, 'Justo por encima del límite');
}

{
  my $r1 = validate_cp('  2 8 0 0 1  ', { strict => 0 });
  ok($r1->{valid}, 'Espacios múltiples se normalizan');
  is($r1->{codigo}, '28001', 'Normalización correcta');

  my $r2 = validate_cp('abcde', { strict => 0 });
  ok(!$r2->{valid}, 'Solo letras no se pueden normalizar');
    
  my $r3 = validate_cp('2a8b0c0d1e', { strict => 0 });
  ok($r3->{valid}, 'Números con letras se normalizan');
  is($r3->{codigo}, '28001', 'Extrae números correctamente');
}

{
  my $result = validate_cp('28001');
  ok($result->{valid}, 'Código válido: 28001');
  is($result->{provincia}, 'Madrid', 'Provincia correcta');
  is($result->{iso_3166_2}, 'ES-M', 'ISO 3166-2 correcto');
}

{
  my $result = validate_cp('99999');
  ok(!$result->{valid}, 'Código inválido: 99999');
  like($result->{error}, qr/no asignado/, 'Error correcto para código no asignado');
}

{
  my $result = validate_cp('abcde');
  ok(!$result->{valid}, 'Código inválido: abcde');
  like($result->{error}, qr/5 dígitos/, 'Error correcto para formato inválido');
}

{
  my $result = validate_cp(undef);
  ok(!$result->{valid}, 'Código undefined');
  like($result->{error}, qr/no definido/, 'Error correcto para undefined');
}

{
  my $cp = Business::ES::CodigoPostal->new(codigo => '18001');
  ok($cp->valid, 'Objeto válido creado');
  is($cp->codigo, '18001', 'Código almacenado correctamente');
  is($cp->provincia, 'Granada', 'Provincia correcta');
  is($cp->iso_3166_2, 'ES-GR', 'ISO correcto');
}

{
  my $cp = Business::ES::CodigoPostal->new(
					   codigo => ' 080-01 ',
					   strict => 0
					  );
  ok($cp->valid, 'Normalización funciona');
  is($cp->codigo, '08001', 'Código normalizado correctamente');
}

{
  my $cp = Business::ES::CodigoPostal->new(
					   codigo => ' 080-01 ',
					   strict => 1
					  );
  ok(!$cp->valid, 'Modo strict rechaza formato incorrecto');
}

{
  my $cp = Business::ES::CodigoPostal->new();
  ok($cp->set('41001'), 'Set con código válido');
  is($cp->provincia, 'Sevilla', 'Provincia actualizada correctamente');
  
  ok(!$cp->set('99999'), 'Set con código inválido');
  ok(!$cp->valid, 'Objeto inválido después de set fallido');
}

{
  my $cp1 = Business::ES::CodigoPostal->new(codigo => '50001');
  my $cp2 = Business::ES::CodigoPostal->new({ codigo => '50001' });
  
  is($cp1->codigo, $cp2->codigo, 'Ambos constructores funcionan igual');
}

{
  ok(defined Business::ES::CodigoPostal::ERROR_DIGITS5, 'Constante ERROR_DIGITS5 existe');
  ok(defined Business::ES::CodigoPostal::ERROR_DEFINED, 'Constante ERROR_DEFINED existe');
  ok(defined Business::ES::CodigoPostal::ERROR_ASSIGN , 'Constante ERROR_ASSIGN existe');
}

{
  my $result1 = validate_cp('01000');
  ok($result1->{valid}, 'Código límite inferior válido');
  
  my $result2 = validate_cp('52999');
  ok($result2->{valid}, 'Código límite superior válido');
  
  my $result3 = validate_cp('00999');
  ok(!$result3->{valid}, 'Código por debajo del límite');
  
  my $result4 = validate_cp('53000');
  ok(!$result4->{valid}, 'Código por encima del límite');
}

{
  my @codigos_test = qw(01001 28001 08001 41001 51001 52001);
  
  for my $codigo (@codigos_test) {
    my $result = validate_cp($codigo);
    ok($result->{valid}, "Código $codigo es válido");
    ok(defined $result->{provincia}, "Provincia definida para $codigo");
    ok(defined $result->{iso_3166_2}, "ISO definido para $codigo");
  }
}

{
  my $cp = Business::ES::CodigoPostal->new(codigo => '07001');
  ok($cp->insular, 'Baleares es insular');
  is($cp->region, 'Baleares', 'Región Baleares');
    
  $cp = Business::ES::CodigoPostal->new(codigo => '35001');
  ok($cp->insular, 'Las Palmas es insular');
  is($cp->region, 'Canarias', 'Región Canarias');
  
  $cp = Business::ES::CodigoPostal->new(codigo => '28001');
  ok(!$cp->insular, 'Madrid no es insular');
}

{
  my $cp = Business::ES::CodigoPostal->new(codigo => '51001');
  ok($cp->valid,     'Ceuta válido');
  is($cp->provincia, 'Ceuta', 'Provincia Ceuta');
  is($cp->ca,        'Ceuta', 'CA Ceuta');
  is($cp->region,    'Ceuta', 'Región Ceuta');
  
  $cp = Business::ES::CodigoPostal->new(codigo => '52001');
  ok($cp->valid,      'Melilla válido');
  is($cp->provincia, 'Melilla', 'Provincia Melilla');
  is($cp->ca,        'Melilla', 'CA Melilla');
}

{
  my @provincias = (
		    ['01001', 'Álava', 'País Vasco'],
		    ['02001', 'Albacete', 'Castilla-La Mancha'],
		    ['03001', 'Alicante', 'Comunitat Valenciana'],
		    ['04001', 'Almería', 'Andalucía'],
		    ['05001', 'Ávila', 'Castilla y León'],
		    ['06001', 'Badajoz', 'Extremadura'],
		    ['07001', 'Islas Baleares', 'Illes Balears'],
		    ['08001', 'Barcelona', 'Cataluña'],
		    ['09001', 'Burgos', 'Castilla y León'],
		    ['10001', 'Cáceres', 'Extremadura'],
		    ['11001', 'Cádiz', 'Andalucía'],
		    ['12001', 'Castellón', 'Comunitat Valenciana'],
		    ['13001', 'Ciudad Real', 'Castilla-La Mancha'],
		    ['14001', 'Córdoba', 'Andalucía'],
		    ['15001', 'La Coruña', 'Galicia'],
		    ['16001', 'Cuenca', 'Castilla-La Mancha'],
		    ['17001', 'Gerona', 'Cataluña'],
		    ['18001', 'Granada', 'Andalucía'],
		    ['19001', 'Guadalajara', 'Castilla-La Mancha'],
		    ['20001', 'Guipúzcoa', 'País Vasco'],
		    ['21001', 'Huelva', 'Andalucía'],
		    ['22001', 'Huesca', 'Aragón'],
		    ['23001', 'Jaén', 'Andalucía'],
		    ['24001', 'León', 'Castilla y León'],
		    ['25001', 'Lérida', 'Cataluña'],
		    ['26001', 'La Rioja', 'La Rioja'],
		    ['27001', 'Lugo', 'Galicia'],
		    ['28001', 'Madrid', 'Comunidad de Madrid'],
		    ['29001', 'Málaga', 'Andalucía'],
		    ['30001', 'Murcia', 'Región de Murcia'],
		    ['31001', 'Navarra', 'Comunidad Foral de Navarra'],
		    ['32001', 'Orense', 'Galicia'],
		    ['33001', 'Asturias', 'Principado de Asturias'],
		    ['34001', 'Palencia', 'Castilla y León'],
		    ['35001', 'Las Palmas', 'Canarias'],
		    ['36001', 'Pontevedra', 'Galicia'],
		    ['37001', 'Salamanca', 'Castilla y León'],
		    ['38001', 'Santa Cruz de Tenerife', 'Canarias'],
		    ['39001', 'Cantabria', 'Cantabria'],
		    ['40001', 'Segovia', 'Castilla y León'],
		    ['41001', 'Sevilla', 'Andalucía'],
		    ['42001', 'Soria', 'Castilla y León'],
		    ['43001', 'Tarragona', 'Cataluña'],
		    ['44001', 'Teruel', 'Aragón'],
		    ['45001', 'Toledo', 'Castilla-La Mancha'],
		    ['46001', 'Valencia', 'Comunitat Valenciana'],
		    ['47001', 'Valladolid', 'Castilla y León'],
		    ['48001', 'Vizcaya', 'País Vasco'],
		    ['49001', 'Zamora', 'Castilla y León'],
		    ['50001', 'Zaragoza', 'Aragón'],
		    ['51001', 'Ceuta', 'Ceuta'],
		    ['52001', 'Melilla','Melilla'],
		   );
  
  for my $test (@provincias) {
    my ($codigo, $provincia, $ca) = @$test;
    my $cp = Business::ES::CodigoPostal->new(codigo => $codigo);
    ok($cp->valid, "Código $codigo es válido");
    is($cp->provincia, $provincia, "Provincia correcta: $provincia");
    is($cp->ca, $ca, "CA correcta: $ca");
  }
}

done_testing();
