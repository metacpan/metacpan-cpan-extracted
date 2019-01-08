#-*-Perl-*-
#!perl -T
use 5.010;
use File::Share ':all';
use Test2::V0;
use Test::Script;

plan(4);
script_compiles('scripts/RNAalisplit.pl', 'RNAalisplit.pl compiles');
script_runs(['scripts/RNAalisplit.pl', '--version'], 'RNAalisplit.pl --version runs');

script_compiles('scripts/eval_alignment.pl', 'eval_alignment.pl compiles');
script_runs(['scripts/eval_alignment.pl', '--version'], 'eval_alignment.pl --version runs');

done_testing;

