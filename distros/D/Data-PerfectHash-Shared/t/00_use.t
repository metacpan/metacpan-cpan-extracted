use strict; use warnings; use Test::More;
BEGIN { use_ok('Data::PerfectHash::Shared') or BAIL_OUT('cannot load') }
# Pin the shape, not the literal: a hardcoded version turns every release bump
# into a spurious failure. What matters is that the module carries one.
like $Data::PerfectHash::Shared::VERSION, qr/^\d+\.\d+$/, 'version is set and well-formed';
done_testing;
