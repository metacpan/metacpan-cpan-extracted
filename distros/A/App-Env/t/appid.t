#!perl

use Test2::V0;
use Test::Lib;

use App::Env;

my %AppOpts = ( a => 3 );

# create new App1, with AppOpts signature.
my $obj1 = App::Env->new( 'App1', { AppOpts => \%AppOpts } );
is( $obj1->env('Site1_App1'), 1, "method 1, AppOpts sig" );

# now get App1 again, with AppID signature
my $obj2 = App::Env->new( 'App1', { CacheID => 'AppID',
                                    AppOpts => \%AppOpts } );
is( $obj2->env('Site1_App1'), 2, "method 2, AppID sig" );
is( $obj2->cacheid, 'App::Env::Site1::App1', "method 2, AppID cache id" );

# now try without any special stuff; should get cached version of obj2
my $obj3 = App::Env->new( 'App1' );
is( $obj3->env('Site1_App1'), 2, "method 3, AppID cache" );

# for completeness, should get cached version of obj1
my $obj4 = App::Env->new( 'App1', { AppOpts => \%AppOpts } );
is( $obj4->env('Site1_App1'), 1, "method 4, AppOpts cache" );

done_testing;
