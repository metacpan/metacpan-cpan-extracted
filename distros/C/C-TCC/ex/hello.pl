#!/usr/bin/perl

use lib './lib';
use blib './blib';
use C::TCC;

my $tcc = C::TCC->new();
$tcc->compile_string('int main(){printf("Hello World.\n"); return 0;}');
$tcc->run();
