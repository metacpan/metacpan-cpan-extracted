package MyAppActionChain;

use strict;
use base qw(App::CLI::Extension);
use constant alias => (
                chain      => "ChainTest",
            );

$ENV{APPCLI_NON_EXIT} = 1;
__PACKAGE__->load_plugins(qw(
                         +MyAppActionChain::Plugin::Setup1
                         +MyAppActionChain::Plugin::Setup2
                         +MyAppActionChain::Plugin::Prerun1
                         +MyAppActionChain::Plugin::Prerun2
                         +MyAppActionChain::Plugin::Postrun1
                         +MyAppActionChain::Plugin::Postrun2
                         +MyAppActionChain::Plugin::Finish1
                         +MyAppActionChain::Plugin::Finish2
));

1;

