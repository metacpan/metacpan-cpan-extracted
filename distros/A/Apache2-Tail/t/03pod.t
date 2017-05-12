use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

use FindBin qw($Bin);
use File::Spec::Functions qw(catdir updir);
chdir catdir $Bin, updir;

all_pod_files_ok();
