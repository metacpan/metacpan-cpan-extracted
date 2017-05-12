#!perl

use Test::More tests => 2;

use lib 't';
use App::Env;

my $env = App::Env->new( 'App1' );

$env->setenv( Site1_App1 => 'fooey' );
is( $env->env( 'Site1_App1' ), 'fooey', 'set' );

$env->setenv( 'Site1_App1' );
is( $env->env( 'Site1_App1' ), undef, 'delete' );
