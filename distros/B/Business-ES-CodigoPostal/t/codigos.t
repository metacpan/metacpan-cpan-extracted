#!perl

use strict;
use warnings;
use Test::More;

use_ok('Business::ES::CodigoPostal');

use constant {
	      RE_5DIGIT => qr/Código postal no son 5 dígitos/i,
	      RE_ASSIGN => qr/Código postal no asignado/i,
	      RE_DEFINE => qr/Código postal no definido/i,
	     };

my @tests =
  (
   { codigo => '08001', provincia => 'Barcelona',  iso_3166_2 => 'ES-B' , valid => 1 },
   { codigo => '28013', provincia => 'Madrid',     iso_3166_2 => 'ES-M' , valid => 1 },
   { codigo => '18001', provincia => 'Granada',    iso_3166_2 => 'ES-GR', valid => 1 },
   { codigo => '35001', provincia => 'Las Palmas', iso_3166_2 => 'ES-GC', valid => 1 },
   { codigo => '1 2 3 4 5', valid => 0 , error => RE_5DIGIT },
   { codigo => 'MARMO', valid => 0, error => RE_5DIGIT },
   { codigo => '99999', valid => 0, error => RE_ASSIGN },
   { codigo => ''     , valid => 0, error => RE_DEFINE },
   { codigo => '1234' , valid => 0, error => RE_5DIGIT },
   { codigo => '1234' , valid => 0, iso_3166_2 => undef , error => RE_5DIGIT },
   #{ codigo => "\x{FF11}\x{FF12}\x{FF13}\x{FF14}\x{FF15}", valid => 0, ERROR => RE_5DIGIT },
  );

for my $case (@tests) {
  my $cp = Business::ES::CodigoPostal->new(codigo => $case->{codigo});

  ok(defined $cp, "Instancia creada para $case->{codigo}");
  
  is($cp->valid,    $case->{valid},     "Validez correcta para $case->{codigo}");
  
  if ($case->{valid}) {
    is($cp->provincia   , $case->{provincia} , "Provincia OK para $case->{codigo}");
    is($cp->{iso_3166_2}, $case->{iso_3166_2}, "ISO3166_2 OK para $case->{iso_3166_2}");
  } else {
    like($cp->error     , $case->{error}     , "Error esperado para $case->{codigo}");
  }
}

subtest 'Normalize' => sub {
  my $cp = Business::ES::CodigoPostal->new(codigo => '28-010' , strict => 0);

  ok($cp->{valid} , '28-010 válido');
  is($cp->{codigo}, '28010', 'normaliza guiones/espacios');
};

subtest 'Region' => sub {
  my @t = ({
	    cp => '07001', pv => 'Baleares',
	    cp => '35001', pv => 'Canarias',
	    cp => '38001', pv => 'Canarias',
	    cp => '51001', pv => 'Ceuta',
	    cp => '52001', pv => 'Melilla'
	   });

  for my $T (@t) {
    my $cp = Business::ES::CodigoPostal->new(codigo => $T->{cp});
    is($cp->region, $T->{pv} ,qq{Region $T->{cp} -> $T->{pv}});
  }
};

# set()
my $cp = Business::ES::CodigoPostal->new();

$cp->set('18001');
is($cp->valid    ,                   1, "set() funciona correctamente con 18001");
is($cp->provincia,         'Granada'  , "Provincia correcto tras set()");
is($cp->region,            'Peninsula', "Region correcta");
is($cp->ca,                'Andalucía', "Comunidad Autonoma OK");

$cp->set('989999');
like($cp->error , RE_5DIGIT, "error()    - 989999");
is($cp->valid   ,         0, "is_valid() - 989999");

done_testing;
