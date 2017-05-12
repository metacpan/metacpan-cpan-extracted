package TestApp;

use strict;
use warnings;
use Catalyst;# qw/-Debug/;

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'TestApp',
    'Model::EVDB' => {
        app_key => $ENV{EVDB_APP_KEY},
    },
);

__PACKAGE__->setup;

sub default : Private {
    my ($self, $c, @path) = @_;

    my $method  = join '/', @path;

    my $evdb    = $c->model('EVDB');
    my $results = $evdb->call($method, $c->req->params)
        or die 'Error calling $method: ' . $evdb->errstr;

    use Data::Dumper;
    $c->response->content_type('text/plain');
    $c->response->body(Dumper $results);
}

sub end : Private {
    my ($self, $c) = @_;

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    $c->res->body('Default body from end');
}

1;
