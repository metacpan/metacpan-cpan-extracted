#!perl

use strict;
use warnings FATAL => 'all';

use lib qw(t/lib blib/lib);

use Apache::TestRunPerl ();

# mod_auth can cause test failures if in the wrong spot in the
# Apache chain, so we just make sure it does not get added. (test case: static
# mod_perl build and everything else as a DSO).
Apache::TestConfig::autoconfig_skip_module_add('mod_auth.c');

Apache::TestRunPerl->new->run(@ARGV);
