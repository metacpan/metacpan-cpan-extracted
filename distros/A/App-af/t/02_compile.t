use Test2::V0 -no_srand => 1;
use Test::Script;

script_compiles 'bin/af';
script_compiles 'bin/palien';

done_testing;
