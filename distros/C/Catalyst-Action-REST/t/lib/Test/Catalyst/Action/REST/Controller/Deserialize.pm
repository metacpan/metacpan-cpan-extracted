package Test::Catalyst::Action::REST::Controller::Deserialize;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(
    'action_args' => {
        'test_action_args' => {
            'deserialize_http_methods' => [qw(POST PUT OPTIONS DELETE GET)]
        }
    },
    'stash_key' => 'rest',
    'map'       => {
        'text/x-yaml'        => 'YAML',
        'text/x-data-dumper' => [ 'Data::Serializer', 'Data::Dumper' ],
        'text/broken'        => 'Broken',
    },
);


sub test :Local :ActionClass('Deserialize') {
    my ( $self, $c ) = @_;
    $c->res->output($c->req->data->{'kitty'});
}

sub test_action_args :Local :ActionClass('Deserialize') {
    my ( $self, $c ) = @_;
    $c->res->output($c->req->data->{'kitty'});
}

1;
