package TestAppWithGlobalTrail;

use Moose;
use namespace::autoclean;

extends 'Catalyst';

with 'ActionLogging';

__PACKAGE__->setup(qw/ SpecialAction::Trail /);

__PACKAGE__->meta->make_immutable;

1;
