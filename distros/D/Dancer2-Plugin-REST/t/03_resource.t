use strict;
use warnings;
use Dancer2::Core::Request;
use Test::More import => ['!pass'], tests => 8;
use Plack::Test;
use HTTP::Request::Common qw(GET POST PUT DELETE);

use JSON;

{
    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::REST;
    use Test::More import => ['!pass'];

    set show_errors => 1;
    set serializer => 'JSON';
    set logger => 'console';

    resource user => 
        'get' => \&on_get_user,
        'create' => \&on_create_user,
        'delete' => \&on_delete_user,
        'update' => \&on_update_user;

    my $users = {};
    my $last_id = 0;

    sub on_get_user {
        my $id = params->{'id'};
        { user => $users->{$id} };
    }

    sub on_create_user {
        my $ctx = shift;

        my $id = ++$last_id;
        my $user = JSON::decode_json($ctx->request->body());
        $user->{id} = $id;
        $users->{$id} = $user;

        { user => $users->{$id} };
    }

    sub on_delete_user {
        my $ctx = shift;

        my $id = $ctx->request->params->{'id'};
        my $deleted = $users->{$id};
        delete $users->{$id};
        { user => $deleted };
    }

    sub on_update_user {
        my $ctx = shift;

        my $id = $ctx->request->params->{'id'};
        my $user = $users->{$id};
        return { user => undef } unless defined $user;

        my $user_changed = JSON::decode_json($ctx->request->body());
        $users->{$id} = { %$user, %$user_changed };
        { user => $users->{$id} };
    }

    eval { resource 'failure'; };
    like $@, qr{resource should be given with triggers}, 
        "resource must have at least one action";
}

my $app = Dancer2->runner->psgi_app;

test_psgi $app, sub {
    my $cb = shift;

    my $r = $cb->(GET '/user/1');
    is_deeply decode_json($r->content), {user => undef},
        "user 1 is not defined";

    $r = $cb->(POST '/user', 'Content-Type' => 'application/json', Content => JSON::to_json({name => 'Alexis'}) );
    is_deeply decode_json($r->content), { user => { id => 1, name => "Alexis" } },
        "create user works";

    $r = $cb->(GET '/user/1');
    is_deeply decode_json($r->content), {user => { id => 1, name => 'Alexis'}},
        "user 1 is defined";

    $r = $cb->(PUT '/user/1', 'Content-Type' => 'application/json', Content => JSON::to_json({name => 'Alexis Sukrieh', nick => 'sukria'}) );
    is_deeply decode_json($r->content), {user => { id => 1, name => 'Alexis Sukrieh', nick => 'sukria'}},
        "user 1 is updated";

    $r = $cb->(DELETE '/user/1');
    is_deeply decode_json($r->content), {user => { id => 1, name => 'Alexis Sukrieh', nick => 'sukria'}},
        "user 1 is deleted";

    $r = $cb->(GET '/user/1');
    is_deeply decode_json($r->content), {user => undef},
        "user 1 is not defined";

    $r = $cb->(POST '/user', 'Content-Type' => 'application/json', Content => JSON::to_json({name => 'Franck Cuny'}) );
    is_deeply decode_json($r->content), { user => { id => 2, name => "Franck Cuny" } },
        "create user works";
};

