#
# $Id: 02_pod.t 86 2004-06-18 20:18:01Z james $
#

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

#
# EOF

