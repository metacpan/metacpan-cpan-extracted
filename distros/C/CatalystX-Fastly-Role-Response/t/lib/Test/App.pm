package Test::App;
use Moose;
use namespace::autoclean;

use Test::More;
use Catalyst::Runtime 5.80;

use Catalyst qw/
    -Debug
    +CatalystX::Fastly::Role::Response

    /;

extends 'Catalyst';

__PACKAGE__->config(
    name => 'Test::App',

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
);

# Start the application
__PACKAGE__->setup();

1;

# sub cdn_purge_now {

# }

# use Catalyst qw/
#     +CatalystX::Fastly::Role::Response
#     /;

# extends 'Catalyst';

1;
