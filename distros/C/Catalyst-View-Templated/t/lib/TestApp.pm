package TestApp;
use strict;
use warnings;

use Catalyst;

if ($ENV{TEMPLATED_USE_CONFIG}) {
    __PACKAGE__->config->{'View::Something'}{TEMPLATE_EXTENSION} = '.template';
}

__PACKAGE__->setup;

1;
