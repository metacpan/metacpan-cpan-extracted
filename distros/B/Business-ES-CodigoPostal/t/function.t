#!perl
use strict;
use warnings;
use Test::More;

use_ok('Business::ES::CodigoPostal', qw(validate_cp));

use constant {
              RE_5DIGIT => qr/Código postal no son 5 dígitos/i,
              RE_ASSIGN => qr/Código postal no asignado/i,
              RE_DEFINE => qr/Código postal no definido/i,
              };

subtest 'Codigo Postal válidos' => sub {
  my $r = validate_cp('08001');
  ok($r->{valid}, '08001 válido');
	  
  is($r->{codigo},    '08001'    , 'normaliza a 5 dígitos');
  is($r->{provincia}, 'Barcelona', 'provincia correcto');
  is($r->{error},     undef      , 'sin error');
};

subtest 'Normalize' => sub {
  my $m = validate_cp('28-013' , { strict => 0 });
  ok($m->{valid},  '28-013 válido');
  is($m->{codigo}, '28013', 'normaliza guiones/espacios');
};

subtest 'Error' => sub {
  my @tests = (
	       { codigo => undef  , error => RE_DEFINE },
	       { codigo => '12AB' , error => RE_5DIGIT },
	       { codigo => 99999  , error => RE_ASSIGN },
	      );
  
  foreach my $t (@tests) {
    my $r = validate_cp($t->{codigo});

    ok(!$r->{valid} , 'valid = 0');
    like($r->{error}, $t->{error}, 'Error esperado');
  }
};

done_testing();
