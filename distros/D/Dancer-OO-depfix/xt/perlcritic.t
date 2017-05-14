use strict;
use warnings;

use File::Spec;
use Test::More;

eval "use Test::Perl::Critic";
plan skip_all => "Test::Perl::Critic required" if $@;

my $rcfile = File::Spec->catfile('xt', 'perlcriticrc');

Test::Perl::Critic->import(-profile => $rcfile, -severity => 2);

all_critic_ok();
