use warnings;
use strict;

use Test::More;

ok -f 'lib/DBIx/Class/Schema/Loader/Optional/Dependencies.pod', 'optdep pod present';
cmp_ok
 -M 'lib/DBIx/Class/Schema/Loader/Optional/Dependencies.pod' || 2 ** 15,
 '<',
 -M 'lib/DBIx/Class/Schema/Loader/Optional/Dependencies.pm',
 'optdep pod newer than pm';

done_testing;
