use Test2::V0 -no_srand => 1;
use Test::Script qw( script_compiles );

script_compiles 'bin/tarweb';

done_testing;
