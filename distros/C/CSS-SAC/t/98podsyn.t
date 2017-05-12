# 99pod.t -- Minimally check POD for problems.
#
# $Id: 98podsyn.t,v 1.1 2008/07/05 19:45:27 hoehrmann Exp $

use strict;
use warnings;
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
