package App::Donburi::Web::Dispatcher;
use strict;
use warnings;

use Router::Simple;
use App::Donburi::Web::Request;
use Class::Load qw/load_class/;

sub new {
    my $class = shift;

    my $router = Router::Simple->new();
    $router->connect('/', { controller => 'JSONRPC', action => 'call' }, {on_match => \&is_called_json_rpc});
    $router->connect('/', { controller => 'Root', action => 'index' });
    $router->connect('/post', { controller => 'Root', action => 'post' });
    $router->connect('/channel/', { controller => 'Channel', action => 'index' });
    $router->connect('/channel/add', { controller => 'Channel', action => 'add' });
    $router->connect('/channel/delete', { controller => 'Channel', action => 'delete' });

    return bless { router => $router }, $class;
}

sub dispatch {
    my ($self, $env) = @_;

    if ( my $p = $self->{router}->match($env) ) {
        my $c = "App::Donburi::Web::C::" . $p->{controller};
        my $action = 'do_' . $p->{action};
        load_class($c);
        my $req = App::Donburi::Web::Request->new($env);
        my $ci = $c->new(req => $req);
        my $res = $ci->$action;
        return $res && ref($res) eq 'ARRAY' ? $res : $ci->auto_render($p->{action}, $res);
    } else {
        return [ 404, [], ['not found'] ];
    }
}

sub is_called_json_rpc {
    my ($env, $match) = @_;
    my $req = App::Donburi::Web::Request->new($env);
    return defined $req->param('params') && defined $req->param('method');
}

1;
