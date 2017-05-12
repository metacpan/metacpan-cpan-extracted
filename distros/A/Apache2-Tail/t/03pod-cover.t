use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

use FindBin qw($Bin);
use File::Spec::Functions qw(catdir updir);
chdir catdir $Bin, updir;
use blib;

all_pod_coverage_ok();
