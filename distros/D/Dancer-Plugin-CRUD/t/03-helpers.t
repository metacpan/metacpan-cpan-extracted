use strict;
use warnings;
use Dancer::ModuleLoader;
use Test::More import => ['!pass'];

plan tests => 16;

{

    package Webservice;
    use Dancer;
    use Dancer::Plugin::CRUD;

    resource 'user(s)' => (
        'read'   => \&on_read_user,
        'create' => \&on_create_user,
        'delete' => \&on_delete_user,
        'update' => \&on_update_user
    );

    my $users   = {};
    my $last_id = 0;

    sub on_read_user {
        my $id = captures->{'user_id'};
        return status_bad_request('id is missing') if !defined $users->{$id};
        { user => $users->{$id} };
    }

    sub on_create_user {
        my $id   = ++$last_id;
        my $user = params('body');
        $user->{id} = $id;
        $users->{$id} = $user;

        { user => $users->{$id} };
    }

    sub on_delete_user {
        my $id      = captures->{'user_id'};
        my $deleted = $users->{$id};
        delete $users->{$id};
        { user => $deleted };
    }

    sub on_update_user {
        my $id   = captures->{'user_id'};
        my $user = $users->{$id};
        return 404 => 'user undef' unless defined $user;

        $users->{$id} = { %$user, %{ params('body') } };
        { user => $users->{$id} };
    }

}

use Dancer::Test;

my $r = dancer_response( GET => '/user/1' );
is $r->{status}, 400, 'HTTP code is 400';
is $r->{content}->{error}, 'id is missing', 'Valid content';

$r = dancer_response( POST => '/user', { body => { name => 'Foo' } } );
is $r->{status}, 201, 'HTTP code is 201';
is_deeply $r->{content}, { user => { id => 1, name => "Foo" } },
  "create user works";

$r = dancer_response( GET => '/user/1' );
is $r->{status}, 200, 'HTTP code is 200';
is_deeply $r->{content}, { user => { id => 1, name => 'Foo' } },
  "user 1 is defined";

$r = dancer_response(
    PUT => '/user/1',
    {
        body => {
            nick => 'foobar',
            name => 'Foo Bar'
        }
    }
);
is $r->{status}, 202, 'HTTP code is 202';
is_deeply $r->{content},
  { user => { id => 1, name => 'Foo Bar', nick => 'foobar' } },
  "user 1 is updated";

$r = dancer_response(
    PUT => '/user/23',
    {
        body => {
            nick => 'john doe',
            name => 'John Doe'
        }
    }
);
is $r->{status}, 404, 'HTTP code is 404';
is_deeply $r->{content}->{error}, 'user undef', 'valid content';

$r = dancer_response( DELETE => '/user/1' );
is_deeply $r->{content},
  { user => { id => 1, name => 'Foo Bar', nick => 'foobar' } },
  "user 1 is deleted";
is $r->{status}, 202, 'HTTP code is 202';

$r = dancer_response( GET => '/user/1' );
is $r->{status}, 400, 'HTTP code is 400';
is_deeply $r->{content}->{error}, 'id is missing', 'valid response';

$r = dancer_response( POST => '/user', { body => { name => 'John Doe' } } );
is_deeply $r->{content}, { user => { id => 2, name => "John Doe" } },
  "id is correctly increased";
is $r->{status}, 201, 'HTTP code is 201';

