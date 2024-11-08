use Test::More;
use feature ":all";

use Data::JPack;

say STDERR "JS REsources are ", "@{[Data::JPack::js_paths]}";

say STDERR "JS REsources are ", "@{[Data::JPack::resource_map]}";

ok 1;

done_testing;
