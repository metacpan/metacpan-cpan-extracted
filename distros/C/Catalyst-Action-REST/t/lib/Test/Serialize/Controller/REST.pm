package Test::Serialize::Controller::REST;

use namespace::autoclean;
use Moose;

BEGIN { extends qw/Catalyst::Controller::REST/ };

__PACKAGE__->config(
    'namespace' => '',
    'stash_key' => 'rest',
    'map'       => {
        'text/html'          => 'YAML::HTML',
        'text/xml'           => 'XML::Simple',
        'text/x-yaml'        => 'YAML',
        'application/json'   => 'JSON',
        'text/x-json'        => 'JSON',
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
        'text/view'   => [ 'View', 'Simple' ],
        'text/explodingview' => [ 'View', 'Awful' ],
        'text/broken' => 'Broken',
        'text/javascript', => 'JSONP',
        'application/x-javascript' => 'JSONP',
        'application/javascript' => 'JSONP',
        'text/my-csv' => [
            'Callback', {
                deserialize => sub { return {split /,/, shift } },
                serialize   => sub { my $d = shift; join ',', %$d }
            }
        ],
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
