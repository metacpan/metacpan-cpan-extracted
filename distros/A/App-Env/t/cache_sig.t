#!perl

use Test2::V0;
use Test::Lib;

use App::Env;

#############################################################

# check if environment signature is working

# no AppOpts
my $obj1 = App::Env->new( 'App1' );
is( $obj1->env('Site1_App1'), 1, "no AppOpts: create" );

# make sure that next attempt is cached
my $obj2 = App::Env->new( 'App1' );
is( $obj2->env('Site1_App1'), 1, "no AppOpts: cache check" );

my %AppOpts = ( a => 1 );

# same environment, different signature
my $obj3 = App::Env->new( 'App1', { AppOpts => \%AppOpts } );
is( $obj3->env('Site1_App1'), 2, "AppOpts: create" );

# make sure that last one was cached
my $obj4 = App::Env->new( 'App1', { AppOpts => \%AppOpts } );
is( $obj4->env('Site1_App1'), 2, "AppOpts:, cache check" );

done_testing;
