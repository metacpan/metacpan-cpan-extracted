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

plan tests => 7;

{
    package Webservice;
    use Dancer;
    use Dancer::Plugin::Resource;
    use Test::More import => ['!pass'];

    # turn off serialization
    no warnings 'once';

    resource 'user';

    my $users = {};
    my $last_id = 0;

    sub GET_user {
        my $id = params->{'user_id'};
        { user => $users->{$id} };
    }

    sub POST_user {
        my $id = ++$last_id;
        my $user = params('body');
        $user->{id} = $id;
        $users->{$id} = $user;

        { user => $users->{$id} };
    }

    sub DELETE_user {
        my $id = params->{'user_id'};
        my $deleted = $users->{$id};
        delete $users->{$id};
        { user => $deleted };
    }

    sub PUT_user {
        my $id = params->{'user_id'};
        my $user = $users->{$id};
        return { user => undef } unless defined $user;

        $users->{$id} = { %$user, %{params('body')} };
        { user => $users->{$id} };
    }
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

