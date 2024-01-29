#! perl

use Test2::V0;

use Capture::Tiny;

ok( lives { require App::Env; App::Env->import } )
  or note $@;

done_testing;
