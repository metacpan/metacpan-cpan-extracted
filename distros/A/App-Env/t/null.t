#!perl

use Test::More tests => 4;

use strict;
use warnings;
use App::Env;


delete $ENV{NULL_TEST};
my $null1 = App::Env->new( 'null', { Cache => 0 });

ok ( ! defined $null1->env( 'NULL_TEST' ), 'null 1: no env' );


$ENV{NULL_TEST} = 1;

ok ( ! defined $null1->env( 'NULL_TEST' ), 'null 1: still no env' );

my $null2 = App::Env->new( 'null', { Cache => 0 });

ok ( defined $null2->env( 'NULL_TEST' ) && $null2->env('NULL_TEST') == 1,
    'null 2: env');


$null2->setenv( NULL_TEST => 3 );

ok ( ! defined $null1->env( 'NULL_TEST' ), 'null 1: again, still no env' );
