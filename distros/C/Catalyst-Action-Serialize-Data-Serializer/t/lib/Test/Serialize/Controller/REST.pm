package Test::Serialize::Controller::REST;

use namespace::autoclean;
use Moose;

BEGIN { extends qw/Catalyst::Controller::REST/ };

__PACKAGE__->config(
    'namespace' => '',
    'stash_key' => 'rest',
    'map'       => {
        'text/x-data-dumper' => [ 'Data::Serializer', 'Data::Dumper' ],
        'text/x-data-denter' => [ 'Data::Serializer', 'Data::Denter' ],
        'text/x-data-taxi'   => [ 'Data::Serializer', 'Data::Taxi' ],
        'application/x-storable' => [ 'Data::Serializer', 'Storable' ],
        'application/x-freezethaw' =>
            [ 'Data::Serializer', 'FreezeThaw' ],
        'text/x-config-general' =>
            [ 'Data::Serializer', 'Config::General' ],
        'text/x-php-serialization' =>
             [ 'Data::Serializer', 'PHP::Serialization' ],
    },
);

sub monkey_put : Local : ActionClass('Deserialize') {
    my ( $self, $c ) = @_;
    if ( ref($c->req->data) eq "HASH" ) {
        my $out = ($c->req->data->{'sushi'}||'') . ($c->req->data->{'chicken'}||'');
        utf8::encode($out);
        $c->res->output( $out );
    } else {
        $c->res->output(1);
    }
}

sub monkey_get : Local : ActionClass('Serialize') {
    my ( $self, $c ) = @_;
    $c->stash->{'rest'} = { monkey => 'likes chicken!', };
}

sub xss_get : Local : ActionClass('Serialize') {
    my ( $self, $c ) = @_;
    $c->stash->{'rest'} = { monkey => 'likes chicken > sushi!', };
}


1;
