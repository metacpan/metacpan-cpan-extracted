
use strict;
use warnings;
use File::Spec::Functions qw( catfile );
use Alien::SwaggerUI;
use Mojolicious::Lite;

get '/swagger/*path' => { path => 'index.html' }, sub {
    my ( $c ) = @_;
    my $path = catfile( Alien::SwaggerUI->root_dir, $c->stash( 'path' ) );
    my $file = Mojo::Asset::File->new( path => $path );
    $c->reply->asset( $file );
};

app->start;
