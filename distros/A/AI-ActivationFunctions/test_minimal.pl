#!/usr/bin/perl
use strict;
use warnings;

# Teste MÍNIMO - sem usar o módulo ainda
print "1. Testando funções básicas...\n";

# Defina as funções localmente primeiro
sub relu {
    my ($x) = @_;
    return $x > 0 ? $x : 0;
}

sub tanh_simple {
    my ($x) = @_;
    my $e2x = exp(2 * $x);
    return ($e2x - 1) / ($e2x + 1);
}

# Teste
print "   relu(5) = " . relu(5) . " (esperado: 5)\n";
print "   relu(-3) = " . relu(-3) . " (esperado: 0)\n";
print "   tanh(0) = " . tanh_simple(0) . " (esperado: ~0)\n";

print "\n2. Agora testando o módulo...\n";

# Tente carregar o módulo
eval {
    # Adiciona lib ao @INC
    unshift @INC, 'lib';
    require AI::ActivationFunctions;
    print "   ✓ Módulo carregado\n";
    
    # Testa uma função
    my $test = AI::ActivationFunctions::relu(10);
    print "   ✓ relu(10) = $test\n";
    
    1;
} or do {
    print "   ✗ Erro: $@\n";
    
    # Mostra o arquivo se houver erro
    if (-f 'lib/AI/ActivationFunctions.pm') {
        print "\nConteúdo do arquivo (primeiras 20 linhas):\n";
        open my $fh, '<', 'lib/AI/ActivationFunctions.pm' or die $!;
        my $linenum = 0;
        while (<$fh>) {
            $linenum++;
            print "$linenum: $_";
            last if $linenum >= 20;
        }
        close $fh;
    }
};

print "\nFeito!\n";
