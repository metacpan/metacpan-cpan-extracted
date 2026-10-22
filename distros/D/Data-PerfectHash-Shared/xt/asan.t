use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Instrumented;
Instrumented::run('asan', 'ASAN');
