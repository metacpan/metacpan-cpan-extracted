package TestApp;

use strict;
use warnings;
use Catalyst::Runtime '5.70';
use Catalyst qw( +TestApp::Plugin::ErrorMessage );

__PACKAGE__->setup;

1;
