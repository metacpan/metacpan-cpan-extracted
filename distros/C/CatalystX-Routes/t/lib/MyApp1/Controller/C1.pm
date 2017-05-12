package MyApp1::Controller::C1;

use Moose;
use CatalystX::Routes;

BEGIN { extends 'Catalyst::Controller' }

our %REQ;

sub _get      { $REQ{get}++ }
sub _get_html { $REQ{get_html}++ }
sub _post     { $REQ{post}++ }
sub _put      { $REQ{put}++ }
sub _del      { $REQ{delete}++ }

get '/foo' => \&_get;

get_html '/foo' => \&_get_html;

post '/foo' => \&_post;

put '/foo' => \&_put;

del '/foo' => \&_del;

get 'bar'=> \&_get;

get_html 'bar'=> \&_get_html;

post 'bar'=> \&_post;

put 'bar'=> \&_put;

del 'bar'=> \&_del;

chain_point '_set_chain1'
    => chained '/'
    => path_part 'chain1'
    => capture_args 1
    => sub { $REQ{chain1} = $_[2] };

chain_point '_set_chain2'
    => chained '_set_chain1'
    => path_part 'chain2'
    => capture_args 1
    => sub { $REQ{chain2} = $_[2] };

get 'baz'
    => chained '_set_chain2'
    => args 1
    => sub { $REQ{baz} = $_[2] };

chain_point '_set_user'
    => chained '/'
    => path_part 'user'
    => capture_args 1
    => sub { $REQ{user} = $_[2] };

get q{}
    => chained '_set_user'
    => args 0
    => sub { $REQ{user_end} = $REQ{user} };

chain_point '_set_thing'
    => chained '/'
    => path_part 'thing'
    => capture_args 1
    => sub { $REQ{thing} = $_[2] };

get q{}
    => chained '_set_thing'
    => args 0
    => sub { $REQ{thing_end} = $REQ{thing} };

sub normal : Chained('/') : Args(0) {
    $REQ{normal}++;
}

1;
