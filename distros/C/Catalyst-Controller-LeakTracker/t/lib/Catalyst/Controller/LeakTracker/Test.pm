package Catalyst::Controller::LeakTracker::Test;

use strict;
use warnings;

use Catalyst::Runtime 5.80;

use parent qw/Catalyst/;
use Catalyst qw(LeakTracker);

__PACKAGE__->config( name => 'Catalyst::Controller::LeakTracker::Test' );

__PACKAGE__->setup();

1;
