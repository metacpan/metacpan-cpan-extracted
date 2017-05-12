#!/usr/bin/env perl
# $Id: TCLI.User.t 40 2007-04-01 01:56:43Z hacker $

use Test::More qw(no_plan);
use lib 'blib/lib';

# TASK Test suite is not complete. Need testing for catching errors.
BEGIN {
    use_ok('Agent::TCLI::User');
}

#use warnings;
#use strict;

sub user1 {
	my $user1 = Agent::TCLI::User->new({
		'id'		=> 'user1@example.com',
		'protocol'	=> 'jabber',
		'auth'		=> 'read only',
		'verbose'	=> 0,
		'do_verbose'=> sub { diag(@_); },
	});
	return $user1;
}

my $user1 = user1();

is(ref($user1),'Agent::TCLI::User','new user1 object');

my $user2 = Agent::TCLI::User->new(
		'verbose'	=> 0,
		'do_verbose'=> sub { diag(@_); },
);

is(ref($user2),'Agent::TCLI::User', 'new user2 object' );

ok($user2->id('user2@example.com'), '$user2->id set' );
is($user2->id,'user2@example.com' , '$user2->id get' );

ok($user2->protocol('email'), '$user2->protocol set' );
is($user2->protocol,'email' , '$user2->protocol get' );

ok($user2->auth('master'), '$user2->auth set' );
is($user2->auth,'master' , '$user2->auth get' );

# Test name get methods
is($user1->get_name,'user1','$user1->get_name from init');
is($user2->get_name,'user2','$user2->get_name from id set');

# Test domain get methods
is($user1->get_domain,'example.com','$user1->get_domain from init');
is($user2->get_domain,'example.com','$user2->get_domain from id set');

# user is authorized
#not_authorized ( { id	   =>  value,   # user id. Will strip off resource
#				  protocol =>  qr(jabber),   # optional regex for protocol
#				  auth	   =>  qr(master|writer),   # option regex for auth
#				} );

ok( !$user1->not_authorized(
				{ id	   =>  'user1@example.com',   # user id. Will strip off resource
				  auth	   =>  qr(read only),   # option regex for auth
				}), 'user1 not_authorized no protocol' );
ok( !$user1->not_authorized(
				{ id	   =>  'user1@example.com',   # user id. Will strip off resource
				  protocol =>  qr(jabber),   		# optional regex for protocol
				}), 'user1 not_authorized no auth' );

my @auths = (
				{ id	   =>  'user1@example.com',   # user id. Will strip off resource
				  protocol =>  qr(jabber),   		# optional regex for protocol
				  auth	   =>  qr(read only),   # option regex for auth
				  user1	   => '',
				  user2	   => 'This is not me',
				  msg	   =>  'user1 exact',
				},
				{ id	   =>  'user1@example.com/resource',   # user id. Will strip off resource
				  protocol =>  qr(jabber),   		# optional regex for protocol
				  auth	   =>  qr(read only),   # option regex for auth
				  user1	   => '',
				  user2	   => 'This is not me',
				  msg	   =>  'user1 with resource',
				},
				{ id	   =>  'user1@example.com',   # user id. Will strip off resource
				  protocol =>  qr(jabber|email),   		# optional regex for protocol
				  auth	   =>  qr(read only),   # option regex for auth
				  user1	   => '',
				  user2	   => 'This is not me',
				  msg	   =>  'user1 multiple protocols',
				},
				{ id	   =>  'user1@example.com',   # user id. Will strip off resource
				  protocol =>  qr(jabber),   		# optional regex for protocol
				  auth	   =>  qr(read only|master),   # option regex for auth
				  user1	   => '',
				  user2	   => 'This is not me',
				  msg	   =>  'user1 multiple auths',
				},
				{ id	   =>  'user1@xample.com',   # user id. Will strip off resource
				  protocol =>  qr(jabber),   		# optional regex for protocol
				  auth	   =>  qr(read only),   # option regex for auth
				  user1	   => 'This is not me',
				  user2	   => 'This is not me',
				  msg	   =>  'user1 domain wrong',
				},
				{ id	   =>  'user1@example.com\resource',   # user id. Will strip off resource
				  protocol =>  qr(jabber),   		# optional regex for protocol
				  auth	   =>  qr(read only),   # option regex for auth
				  user1	   => 'This is not me',
				  user2	   => 'This is not me',
				  msg	   =>  'user1 bad resource',
				},
				{ id	   =>  'user1@example.com',   # user id. Will strip off resource
				  protocol =>  qr(email),   		# optional regex for protocol
				  auth	   =>  qr(read only),   # option regex for auth
				  user1	   => 'Improper protocol',
				  user2	   => 'This is not me',
				  msg	   =>  'user1 wrong protocols',
				},
				{ id	   =>  'user1@example.com',   # user id. Will strip off resource
				  protocol =>  qr(jabber),   		# optional regex for protocol
				  auth	   =>  qr(master),   # option regex for auth
				  user1	   => 'Inadequate authorization',
				  user2	   => 'This is not me',
				  msg	   =>  'user1 wrong auths',
				},
				{ id	   =>  'theuser1@example.com',   # user id. Will strip off resource
				  protocol =>  qr(jabber),   		# optional regex for protocol
				  auth	   =>  qr(master),   # option regex for auth
				  user1	   => 'This is not me',
				  user2	   => 'This is not me',
				  msg	   =>  'user1 not theuser1',
				},
				{ id	   =>  'user2@example.com',   # user id. Will strip off resource
				  protocol =>  qr(jabber),   		# optional regex for protocol
				  auth	   =>  qr(master),   # option regex for auth
				  user1	   => 'This is not me',
				  user2	   => 'Improper protocol',
				  msg	   =>  'user1 not user2',
				},
);

foreach my $hash ( @auths ) {

like( $user1->not_authorized(
				{ id	   =>  $hash->{'id'},   # user id. Will strip off resource
				  protocol =>  $hash->{'protocol'},   		# optional regex for protocol
				  auth	   =>  $hash->{'auth'},   # option regex for auth
				}), qr($hash->{'user1'}) , 'user1 not_auth against '.$hash->{'msg'} );
like( $user2->not_authorized(
				{ id	   =>  $hash->{'id'},   # user id. Will strip off resource
				  protocol =>  $hash->{'protocol'},   		# optional regex for protocol
				  auth	   =>  $hash->{'auth'},   # option regex for auth
				}), qr($hash->{'user2'}), 'user2 not_auth against '.$hash->{'msg'} );
} #end foreach auths

# This crashes. Apparently Params::Validate on fail doesn't capture it.
#ok(  $user1->not_authorized(
#				{ id	   =>  'user1@example.com',   # user id. Will strip off resource
#				  protocol =>  qr(jabber),   		# optional regex for protocol
#				  auth	   =>  qr(read only),   # option regex for auth
#				  msg	   =>  'user1',
#				}), 'user1 exact but with extra param' );




