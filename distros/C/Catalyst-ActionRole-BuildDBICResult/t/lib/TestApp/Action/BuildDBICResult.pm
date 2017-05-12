package # hide from PAUSE
  TestApp::Action::BuildDBICResult;

use Moose;
use namespace::autoclean;

BEGIN {
    extends 'Catalyst::Action';
    with 'Catalyst::ActionRole::BuildDBICResult';
}

__PACKAGE__->meta->make_immutable;

1;
