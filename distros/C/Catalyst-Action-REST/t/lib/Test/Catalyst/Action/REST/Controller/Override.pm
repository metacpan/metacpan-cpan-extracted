package Test::Catalyst::Action::REST::Controller::Override;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(
    'default'   => 'application/json',
    'map'       => {
        'application/json'   => 'YAML', # Yes, this is deliberate!
    },
);

sub test :Local :ActionClass('Serialize') {
    my ( $self, $c ) = @_;
    $c->stash->{'rest'} = {
        lou => 'is my cat',
    };
}

1;
