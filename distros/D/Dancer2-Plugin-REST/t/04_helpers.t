use strict;
use warnings;
use Test::More import => ['!pass'], tests => 17;
use Plack::Test;
use HTTP::Request::Common qw(GET POST PUT DELETE);

use JSON;

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::REST;

    set serializer => 'JSON';

    resource user => 'get' => \&on_get_user,
      'create'    => \&on_create_user,
      'delete'    => \&on_delete_user,
      'update'    => \&on_update_user;

    get '/teapot1' => sub { status_i_m_a_teapot };
    get '/teapot2' => sub { status_418          };

    my $users   = {};
    my $last_id = 0;

    sub on_get_user {
        my $ctx = shift;

        my $id = $ctx->request->params->{'id'};
        return status_bad_request('id is missing') if !defined $users->{$id};
        status_ok( { user => $users->{$id} } );
    }

    sub on_create_user {
        my $ctx = shift;

        my $id = ++$last_id;
        my $user = JSON::decode_json($ctx->request->body());
        $user->{id} = $id;
        $users->{$id} = $user;

        status_created( { user => $users->{$id} } );
    }

    sub on_delete_user {
        my $ctx = shift;

        my $id = $ctx->request->params->{'id'};
        my $deleted = $users->{$id};
        delete $users->{$id};
        status_accepted( { user => $deleted } );
    }

    sub on_update_user {
        my $ctx = shift;

        my $id = $ctx->request->params->{'id'};
        my $user = $users->{$id};
        return status_not_found("user undef") unless defined $user;

        my $user_changed = JSON::decode_json($ctx->request->body());
        $users->{$id} = { %$user, %$user_changed };
        status_accepted { user => $users->{$id} };
    }

}

my $app = Dancer2->runner->psgi_app;

test_psgi $app, sub {
    my $cb = shift;

    my $r = $cb->( GET '/user/1', 'Content-Type' => 'application/json' );
    is( $r->code, 400, 'HTTP code is 400');
    is_deeply( decode_json($r->content) => { error => "id is missing" },
        'Valid content'
    );

    $r = $cb->( POST '/user', 'Content-Type' => 'application/json',
        Content => encode_json( { name => 'Alexis' } )
    );
    is( $r->code, 201, 'HTTP code is 201');
    is_deeply( decode_json( $r->content ), { user => { id => 1, name => "Alexis" } },
        "create user works"
    );

    $r = $cb->( GET '/user/1' );
    is( $r->code, 200, 'HTTP code is 200' );
    is_deeply( decode_json($r->content), { user => { id => 1, name => 'Alexis' } },
        "user 1 is defined"
    );

    $r = $cb->( PUT '/user/1', 'Content-Type' => 'application/json',
        Content => encode_json( {
            nick => 'sukria',
            name => 'Alexis Sukrieh'
        } )
    );
    is( $r->code, 202, 'HTTP code is 202' );
    is_deeply( decode_json($r->content),
        { user => { id => 1, name => 'Alexis Sukrieh', nick => 'sukria' } },
        "user 1 is updated"
    );

    $r = $cb->( PUT '/user/23', 'Content-Type' => 'application/json',
        Content => encode_json( {
            nick => 'john doe',
            name => 'John Doe'
        } )
    );
    is( $r->code, 404, 'HTTP code is 404' );
    is_deeply( decode_json($r->content)->{error}, 'user undef',
        'valid content'
    );

    $r = $cb->( DELETE '/user/1' );
    is_deeply( decode_json($r->content),
        { user => { id => 1, name => 'Alexis Sukrieh', nick => 'sukria' } },
        "user 1 is deleted"
    );
    is( $r->code, 202, 'HTTP code is 202' );

    $r = $cb->( GET '/user/1' );
    is( $r->code, 400, 'HTTP code is 400');
    is_deeply( decode_json($r->content)->{error}, 'id is missing',
        'valid response');

    $r = $cb->( POST '/user', 'Content-Type' => 'application/json',
        Content => encode_json( { name => 'Franck Cuny' } )
    );
    is_deeply( decode_json($r->content), { user => { id => 2, name => "Franck Cuny" } },
        "id is correctly increased"
    );
    is( $r->code, 201, 'HTTP code is 201' );

    subtest 'teapot status helpers' => sub {
        for ( map { '/teapot'.$_ } 1..2 ) {
            $r = $cb->( GET $_ );
            is( $r->code, 418, $_ );
        }
    };
}
