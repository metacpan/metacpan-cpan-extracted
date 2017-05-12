package TestAppGlobals::View::Mason;

use Moose;
use namespace::autoclean;

extends 'Catalyst::View::HTML::Mason';

__PACKAGE__->config(
    globals => '$affe',
    interp_args => {
        comp_root => TestAppGlobals->path_to('root'),
    },
);

__PACKAGE__->meta->make_immutable;

1;
