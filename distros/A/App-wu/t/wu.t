use warnings;
use strict;
use Test::More;

BEGIN { use_ok 'App::wu', 'import module' };

ok my $wu = App::wu->new('timbuktu', '123456789'), 'constructor';

done_testing;
