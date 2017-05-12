#-*-perl-*-
#$Id: 098_pod.t 2 2012-10-30 14:31:22Z maj $
use Test::More;
use Module::Build;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
plan skip_all => "Not calling from build process" unless Module::Build->current;
all_pod_files_ok();
