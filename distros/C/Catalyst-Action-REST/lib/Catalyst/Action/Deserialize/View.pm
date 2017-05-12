package Catalyst::Action::Deserialize::View;
$Catalyst::Action::Deserialize::View::VERSION = '1.20';
use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';

sub execute {
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
