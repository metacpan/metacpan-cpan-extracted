# $Id: pod.t,v 1.1 2006/10/20 17:36:52 sullivan Exp $

use Test::More;
eval 'use Test::Pod';
plan skip_all => "Test::Pod is not installed" if $@;
all_pod_files_ok();

1;
