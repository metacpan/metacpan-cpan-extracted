#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Pular se PDL não estiver instalado
BEGIN {
    eval {
        require PDL;
        1;
    } or do {
        plan skip_all => 'PDL não está instalado';
        exit 0;
    };
}

# Continuar com os testes
plan tests => 1;

# Testar se podemos usar PDL com nosso módulo
use_ok('AI::ActivationFunctions');

# Nota: Nosso módulo atual não tem suporte a PDL,
# então apenas testamos o carregamento

done_testing();
