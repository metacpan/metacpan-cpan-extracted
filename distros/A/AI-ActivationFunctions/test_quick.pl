#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";

# Testar se o módulo carrega
eval {
    require AI::ActivationFunctions;
    AI::ActivationFunctions->import(qw(relu prelu sigmoid));
    1;
} or die "Erro ao carregar módulo: $@";

print "=== Teste Rápido ===\n\n";

print "relu(5) = " . AI::ActivationFunctions::relu(5) . "\n";
print "relu(-3) = " . AI::ActivationFunctions::relu(-3) . "\n";
print "prelu(-2, 0.1) = " . AI::ActivationFunctions::prelu(-2, 0.1) . "\n";
print "sigmoid(0) = " . AI::ActivationFunctions::sigmoid(0) . "\n";

my $arr = [-2, -1, 0, 1, 2];
my $result = AI::ActivationFunctions::relu($arr);
print "relu([-2,-1,0,1,2]) = [" . join(", ", @$result) . "]\n";

print "\nOK!\n";
