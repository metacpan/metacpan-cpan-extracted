package MyAppActionChain::ChainTest;

use strict;
use base qw(App::CLI::Command);

sub run {

    my($self, @args) = @_;
    $main::RESULT{run} = __PACKAGE__;
}
1;

