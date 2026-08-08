package App::View::TT;

use Moose;
extends 'Catalyst::View::TT';

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
