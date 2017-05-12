use strict;
use warnings;
use Dancer::ModuleLoader;
use Test::More import => ['!pass'];

plan tests => 6;

{

    package Webservice;
    use Dancer;
    use Dancer::Plugin::Resource;

    resource 'users';

    my $users   = {};
    my $last_id = 0;

    sub GET_user {
        my $id = params->{'user_id'};
        return status_bad_request('id is missing') if !defined $users->{$id};
        status_ok( { user => $users->{$id} } );
    }

    sub user_POST {
        my $id   = ++$last_id;
        my $user = params('body');
        $user->{id} = $id;
        $users->{$id} = $user;

        status_created( { user => $users->{$id} } );
    }
}

use Dancer::Test;

my $r = dancer_response( GET => '/users/1' );
is $r->{status}, 400, 'HTTP code is 400';
is $r->{content}->{error}, 'id is missing', 'Valid content';

$r = dancer_response( POST => '/users', { body => { name => 'Alexis' } } );
is $r->{status}, 201, 'HTTP code is 201';
is_deeply $r->{content}, { user => { id => 1, name => "Alexis" } },
  "create user works";

$r = dancer_response( GET => '/users/1' );
is $r->{status}, 200, 'HTTP code is 200';
is_deeply $r->{content}, { user => { id => 1, name => 'Alexis' } },
  "user 1 is retrieved via user_id param";
