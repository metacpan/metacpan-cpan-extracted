package Test::Catalyst::Action::REST::Controller::DeserializeMultiPart;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(
    'stash_key' => 'rest',
    'map'       => {
        'text/x-yaml'        => 'YAML',
        'text/x-data-dumper' => [ 'Data::Serializer', 'Data::Dumper' ],
        'text/broken'        => 'Broken',
    },
);

sub test :Local ActionClass('DeserializeMultiPart') DeserializePart('REST') {
    my ( $self, $c ) = @_;
    $DB::single=1;
    $c->res->output($c->req->data->{'kitty'} . '|' . $c->req->uploads->{other}->size);
}

1;
