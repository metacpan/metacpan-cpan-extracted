package TestApp;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

use Catalyst qw/ConfigLoader/;

our $VERSION = '0.01';
__PACKAGE__->config( name => 'TestApp',
                     'Engine::XMPP2' =>
                     {
                      username => 'foo',
                      domain => 'example.com'
                     });
__PACKAGE__->setup;


1;
