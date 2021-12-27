package TestApp::Controller::Action::Path;

use strict;
use base 'Catalyst::Controller';

__PACKAGE__->config(
    actions => {
      'one' => { 'Path' => [ 'a path with spaces' ] },
      'two' => { 'Path' => "åäö" },
      'six' => { 'Local' => undef },
    },
);

sub one : Action Path("this_will_be_overriden") {
}

sub two : Action {
}

sub six {
}

1;
