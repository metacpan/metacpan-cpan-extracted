use strict;
use warnings;
use Dancer::ModuleLoader;
use Test::More import => ['!pass'];

# Dancer::Test had a bug in version previous 1.3059_01 that prevent this test
# from running correctly.
my $dancer_version = eval "\$Dancer::VERSION";
$dancer_version =~ s/_//g;
plan skip_all => "Dancer 1.3059_01 is needed for this test (you have $dancer_version)"
  if $dancer_version < 1.305901;

plan tests => 8;

{
    package Webservice;
    use Dancer;
    use Dancer::Plugin::REST;
    use Test::More import => ['!pass'];

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
        my $id = ++$last_id;
        my $user = params('body');
        $user->{id} = $id;
        $users->{$id} = $user;

        { user => $users->{$id} };
    }

    sub on_delete_user {
        my $id = params->{'id'};
        my $deleted = $users->{$id};
        delete $users->{$id};
        { user => $deleted };
    }

    sub on_update_user {
        my $id = params->{'id'};
        my $user = $users->{$id};
        return { user => undef } unless defined $user;

        $users->{$id} = { %$user, %{params('body')} };
        { user => $users->{$id} };
    }

    eval { 
        resource failure => 
            get => sub { 'GET' },
            woobly => sub { },
    };
    like $@, qr{action 'woobly' not recognized}, 
        "resource must have 4 hooks";
}

use Dancer::Test;

my $r = dancer_response(GET => '/user/1');
is_deeply $r->{content}, {user => undef},
    "user 1 is not defined";

$r = dancer_response(POST => '/user', { body => {name => 'Alexis' }});
is_deeply $r->{content}, { user => { id => 1, name => "Alexis" } },
    "create user works";

$r = dancer_response(GET => '/user/1');
is_deeply $r->{content}, {user => { id => 1, name => 'Alexis'}},
    "user 1 is defined";

$r = dancer_response(PUT => '/user/1', { 
    body => {
        nick => 'sukria', 
        name => 'Alexis Sukrieh' 
    }
});
is_deeply $r->{content}, {user => { id => 1, name => 'Alexis Sukrieh', nick => 'sukria'}},
    "user 1 is updated";

$r = dancer_response(DELETE => '/user/1');
is_deeply $r->{content}, {user => { id => 1, name => 'Alexis Sukrieh', nick => 'sukria'}},
    "user 1 is deleted";

$r = dancer_response(GET => '/user/1');
is_deeply $r->{content}, {user => undef},
    "user 1 is not defined";

$r = dancer_response(POST => '/user', { 
    body => {
        name => 'Franck Cuny' 
    }
});
is_deeply $r->{content}, { user => { id => 2, name => "Franck Cuny" } },
    "id is correctly increased";

