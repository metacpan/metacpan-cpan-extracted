#! perl

use Test2::V0;

use Capture::Tiny;

eval  "use App::Env;";

is ( $@, '', "succeeds" )
  or note $@;

done_testing;
