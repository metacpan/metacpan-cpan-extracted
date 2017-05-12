use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::ApacheTestRun;
use base 'Apache::SWIT::Maker::Skeleton';

sub output_file { return 't/apache_test_run.pl'; }

sub template { return <<ENDM; }
use Apache::SWIT::Test::Apache;
Apache::SWIT::Test::Apache->swit_run;
ENDM

1;
