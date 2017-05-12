package Test::Catalyst::Action::REST::Controller::Serialize;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(
    'default'   => 'text/x-yaml',
    'stash_key' => 'rest',
    'map'       => {
        'text/x-yaml'        => 'YAML',
        'application/json'   => 'JSON',
        'text/x-data-dumper' => [ 'Data::Serializer', 'Data::Dumper' ],
        'text/broken'        => 'Broken',
    },
);

sub test :Local :ActionClass('Serialize') {
    my ( $self, $c ) = @_;
    $c->stash->{'rest'} = {
        lou => 'is my cat',
    };
}

sub test_second :Local :ActionClass('Serialize') {
    my ( $self, $c ) = @_;
    # 'serialize_content_type' is configured in the test config in t/conf
    $c->stash->{'serialize_content_type'} = $c->req->params->{'serialize_content_type'};
    $c->stash->{'rest'} = {
        lou => 'is my cat',
    };
}

# For testing saying 'here is an explicitly empty body, do not serialize'
sub empty : Chained('/') PathPart('serialize') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash( rest => { foo => 'bar' } );
}

# Normal case
sub empty_serialized :Chained('empty') Args(0) ActionClass('Serialize') {
}

# Blank body
sub empty_not_serialized_blank :Chained('empty') Args(0) ActionClass('Serialize') {
    my ($self, $c) = @_;
    $c->res->body('');
}

# Explicitly set a view
sub explicit_view :Chained('empty') Args(0) ActionClass('Serialize') {
    my ($self, $c) = @_;
    $c->stash->{current_view} = '';
}

1;
