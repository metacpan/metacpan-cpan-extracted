#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

my $CLASS = 'Business::ES::NIF';

subtest 'Carga del módulo' => sub {
  use_ok($CLASS) or bail_out("No se pudo cargar $CLASS");
  ok($CLASS->VERSION, "$CLASS tiene versión definida");
};

done_testing;
