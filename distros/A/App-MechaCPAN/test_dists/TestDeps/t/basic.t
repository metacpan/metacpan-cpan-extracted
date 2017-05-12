use strict;
use Test::More;
use TestDeps;
use Try::Tiny;

# replace with the actual test
#is(try { die } catch { 0 }, 0, 'Use okay');
ok(try { die } catch { 1 });

done_testing;
