package Test::Serialize::Controller::JSON;

use namespace::autoclean;
use Moose;

BEGIN { extends qw/Catalyst::Controller::REST/ };

__PACKAGE__->config(
    'stash_key' => 'rest',
    'json_options' => {
        relaxed => 1,
    },
    'map'       => {
        'text/x-json'        => 'JSON',
    },
);

sub monkey_json_put : Path("/monkey_json_put") : ActionClass('Deserialize') {
    my ( $self, $c ) = @_;
    if ( ref($c->req->data) eq "HASH" ) {
        my $out = ($c->req->data->{'sushi'}||'') . ($c->req->data->{'chicken'}||'');
        utf8::encode($out);
        $c->res->output( $out );
    } else {
        $c->res->output(1);
    }
}

1;
