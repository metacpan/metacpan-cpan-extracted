package TestApp;
use strict;
use warnings;

use Catalyst::Runtime 5.70;

use base qw/Catalyst/;
use Catalyst qw/+CatalystX::Features
                +CatalystX::Features::Lib
                +CatalystX::Features::Plugin::I18N
                /;

__PACKAGE__->config( name => 'TestApp' );

# Start the application
__PACKAGE__->setup();

1;
