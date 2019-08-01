use v5.14;
use warnings;
use FindBin ();
use Test::Perl::Critic -profile => "$FindBin::Bin/criticrc";

all_critic_ok("$FindBin::Bin/../lib", "$FindBin::Bin/../t/lib");
