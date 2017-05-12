#!/perl

use 5.010;
use strict;
use warnings;
use Data::Unixish::Apply;
use Test::More 0.98;

is_deeply(Data::Unixish::Apply::apply(in=>[1, 2, 3, 4, 5], functions=>["sum"]), [200, "OK", [15]]);
is_deeply(Data::Unixish::Apply::apply(in=>[1, 2, 5, 4, 3], functions=>["sort", [lpad => {width=>2, char=>"0"}]]), [200, "OK", ["01", "02", "03", "04", "05"]]);

done_testing;
