use strict;
use warnings;
use Test::More tests => 5;

package MyApp;
use parent 'CGI::Application';
use CGI::Application::Plugin::Header;

sub setup {
    my $self = shift;
    $self->run_modes( start => sub { 'Hello World' } );
}

sub cgiapp_postrun {
    my ( $self, $body_ref ) = @_;
    $self->header->set( 'Content-Length' => length $$body_ref );
}

package main;

subtest '#header' => sub {
    my $app = MyApp->new;

    can_ok $app, 'header';
    isa_ok $app->header, 'CGI::Header', '#header defaults to CGI::Header object';
    is $app->header->query, $app->query;

    my $header = CGI::Header->new( query => $app->query );

    is $app->header($header), $header, 'set #header';
    is $app->header, $header, '#header is updated';
};

subtest '#BUILD' => sub {
    my $query  = CGI->new;
    my $header = CGI::Header->new( query => $query );
    my $app    = MyApp->new( query => $query, header => $header );

    is $app->header, $header;
};

subtest '#header_add' => sub {
    my $app = MyApp->new;

    $app->header_add( -cookie => 'foo=bar' );
    is $app->header->cookies, 'foo=bar';

    $app->header_add( -cookie => ['bar=baz'] );
    is_deeply $app->header->cookies, [ 'foo=bar', 'bar=baz' ];

    $app->header_add( -cookie => ['baz=qux'] );
    is_deeply $app->header->cookies, [ 'foo=bar', 'bar=baz', 'baz=qux' ];
};

subtest '#header_props' => sub {
    my $app = MyApp->new;

    is_deeply +{ $app->header_props( -foo => 'bar' ) }, { -foo => 'bar' };
    is_deeply $app->header->header, { foo => 'bar' };

    $app->header->clear->set( -bar => 'baz' );
    is_deeply +{ $app->header_props }, { -bar => 'baz' };
};

subtest '#run' => sub {
    my $app = MyApp->new;
    local $ENV{CGI_APP_RETURN_ONLY} = 1;
    like $app->run, qr{Content-length: 11};
};
