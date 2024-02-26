package MyApp::Controller;

use Moose;

BEGIN { extends 'Dancer2::Controllers::Controller' }

sub hello_world : Route(get => '') {
    "Hello World!";
}

sub foo : Route(get => ) {
    'Foo!';
}

1;

package MyApp::Controller::Two;

use Moose;

BEGIN { extends 'Dancer2::Controllers::Controller' }

sub hello_world : Route(flarb => /) {
    "Hello World!";
}

1;

package MyApp::Controller::Three;

use strict;
use warnings;

1;

use Test::More;
use Test::Exception;
use Plack::Test;
use HTTP::Request::Common;
use Dancer2;
use strict;
use warnings;

use_ok('Dancer2::Controllers');

require Dancer2::Controllers;

dies_ok { Dancer2::Controllers::controllers( ['MyApp::Controller::Two'] ) };
dies_ok { Dancer2::Controllers::controllers( ['MyApp::Controller::Three'] ) };
dies_ok { Dancer2::Controllers::controllers( ['MyApp::Controller'] ) };

done_testing
