package App::Controller::Root;

use v5.14;
use Moose;

use Path::Tiny;

BEGIN {
    extends qw/ Catalyst::Controller /;
}

sub base : Chained('/') PathPart('') Args(0) {
    my ($self, $c) = @_;

    my $params = $c->req->query_params;

    my $file = path( $params->{file} )->basename;
    my $root = path( __FILE__ )->parent(4)->child('static');

    $c->serve_static_file( "${root}/${file}", $params->{type} || undef )

}

1;
