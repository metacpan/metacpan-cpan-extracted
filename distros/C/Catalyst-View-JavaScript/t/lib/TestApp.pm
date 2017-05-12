package 
  TestApp;
our $VERSION = '0.995';

use strict;
use warnings;

use Catalyst::Runtime '5.70';

use base qw/Catalyst/;

__PACKAGE__->config( name => 'TestApp' );

__PACKAGE__->setup();

1;
