use strict; use warnings; use Test::More;
BEGIN { use_ok('Data::PerfectHash::Shared') or BAIL_OUT('cannot load') }
is $Data::PerfectHash::Shared::VERSION, '0.01', 'version';
done_testing;
