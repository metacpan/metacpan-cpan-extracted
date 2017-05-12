use strict;
use warnings;
use Dancer::ModuleLoader;
use Test::More import => ['!pass'];

# Dancer::Test had a bug in version previous 1.3059_01 that prevent this test
# from running correctly.
my $dancer_version = eval "\$Dancer::VERSION";
$dancer_version =~ s/_//g;
plan skip_all =>
  "Dancer 1.3059_01 is needed for this test (you have $dancer_version)"
  if $dancer_version < 1.305901;

plan tests => 9;

{

    package Webservice;
    use Dancer;
    use Dancer::Plugin::CRUD;
    use Test::More import => ['!pass'];

    set serialzier => 'JSON';

    resource 'user(s)' => (
        'altsyntax' => 1,
        'index'     => \&on_index_users,
        'read'      => \&on_read_user,
        'create'    => \&on_create_user,
        'delete'    => \&on_delete_user,
        'update'    => \&on_update_user
    );

    my $users   = {};
    my $last_id = 0;

    sub on_index_users {
        return { users => $users };
    }

    sub on_read_user {
        my $id = captures->{'user_id'};
        return { user => defined $id ? $users->{$id} : undef };
    }

    sub on_create_user {
        my $id   = ++$last_id;
        my $user = params('query');
        $user->{id} = $id;
        $users->{$id} = $user;

        return { user => $users->{$id} };
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
        return { user => undef } unless defined $user;

        $users->{$id} = { %$user, %{ params('query') } };
        { user => $users->{$id} };
    }

}

use Dancer::Test;

my $r = dancer_response( GET => '/users/index.json' );
is_deeply $r->{content}, { users => {} }, "no users defined";

$r = dancer_response( GET => '/user/1/read.json' );
is_deeply $r->{content}, { user => undef }, "user 1 is not defined";

$r = dancer_response(
    GET => '/user/create.json',
    { params => { name => 'Foo' } }
);
is_deeply $r->{content}, { user => { id => 1, name => "Foo" } },
  "create user works";

$r = dancer_response( GET => '/user/1/read.json' );
is_deeply $r->{content}, { user => { id => 1, name => 'Foo' } },
  "user 1 is defined";

$r = dancer_response(
    GET => '/user/1/update.json',
    {
        params => {
            nick => 'foobar',
            name => 'Foo Bar'
        }
    }
);
is_deeply $r->{content},
  { user => { id => 1, name => 'Foo Bar', nick => 'foobar' } },
  "user 1 is updated";

$r = dancer_response( GET => '/user/1/delete.json' );
is_deeply $r->{content},
  { user => { id => 1, name => 'Foo Bar', nick => 'foobar' } },
  "user 1 is deleted";

$r = dancer_response( GET => '/user/1/read' );
is_deeply $r->{content}, { user => undef }, "user 1 is not defined";

$r = dancer_response(
    GET => '/user/create',
    {
        params => {
            name => 'John Doe'
        }
    }
);
is_deeply $r->{content}, { user => { id => 2, name => "John Doe" } },
  "id is correctly increased";

$r = dancer_response( GET => '/users/index' );
is_deeply $r->{content}, { users => { 2 => { id => 2, name => "John Doe" } } },
  "users index complete";

