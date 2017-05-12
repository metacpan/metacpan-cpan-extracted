package TestApp;

use strict;
use warnings;

use Catalyst::Runtime '5.70';
use Test::More;

use URI;
use FindBin;

use Catalyst qw(ConfigLoader::Remote Static::Simple);


__PACKAGE__->config(
    'Plugin::ConfigLoader::Remote' => {
        files => [
            URI->new("file://$FindBin::Bin/conf/test1.yml")
        ]
    }
);

__PACKAGE__->setup;

sub root : Chained('/') PathPart('') CaptureArgs(0) {
}

sub base : Chained('root') CaptureArgs(0) PathPart('') {
}

sub test : Chained('base') CaptureArgs(0) {
}

sub scalar : Chained('test') Args(0) {
    my ( $self, $c ) = @_;
    is( $c->config->{scalar}, 'foo' );
}

sub array : Chained('test') Args(0) {
    my ( $self, $c ) = @_;
    is_deeply( $c->config->{array}, [qw/foo bar baz/] );
}

sub hash : Chained('test') Args(0) {
    my ( $self, $c ) = @_;
    is_deeply( $c->config->{hash}, { foo => 'bar' } );
}

sub end : Private {
    my ( $self, $c ) = @_;
    $c->res->body('ok');
}

1;
