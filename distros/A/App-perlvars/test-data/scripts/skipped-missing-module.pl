use strict;
use warnings;

use No::Such::Module::Perlvars::Test;

my $top = 1;

sub run {
    my $unused;
    return $top;
}

run();
