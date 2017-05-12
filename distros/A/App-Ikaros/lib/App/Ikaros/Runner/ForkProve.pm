use strict;
use App::ForkProve;
exit(App::ForkProve->run(@ARGV) ? 0 : 1);
