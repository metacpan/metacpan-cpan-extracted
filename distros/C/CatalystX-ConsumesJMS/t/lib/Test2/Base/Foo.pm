package Test2::Base::Foo;
use Moose;
extends 'Catalyst::Component';
with 'CatalystX::RouteMaster';

sub _kind_name { 'Foo' }

sub _wrap_code {
    my ($self,$appclass,$url,$action,$route) = @_;
    my $code = $route->{code};

    return sub {
        my ($controller,$c) = @_;

        my $body = join '',$c->req->body->getlines;
        my $headers = $c->req->headers;

        $self->$code($body,$headers);

        $c->res->body('nothing');
        return;
    }
}

sub _controller_roles { 'Test2::Role::DefaultAction' }

1;
