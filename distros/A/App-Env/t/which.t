#!perl

use Test2::V0;
use Test::Lib;

use App::Env;

my $app = App::Env->new( 'AppWhich' );

ok ( $app->which( 'appwhich' ), 'found our app!' );
done_testing;
