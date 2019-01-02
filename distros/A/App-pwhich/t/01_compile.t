use Test2::V0 -no_srand => 1;
use Test::Script;

script_compiles('bin/pwhich');
script_compiles('bin/pwhere');

done_testing;
