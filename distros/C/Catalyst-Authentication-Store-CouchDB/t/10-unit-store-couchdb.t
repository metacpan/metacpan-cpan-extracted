#!perl 

use strict;
use warnings;
use FindBin 1.49;
use lib "$FindBin::Bin/lib";

use Test::More 0.98;

BEGIN {
	use_ok( 'Catalyst::Authentication::Store::CouchDB' );
	use_ok( 'Catalyst::Authentication::Store::CouchDB::User' );
}



my $config = {
    couchdb_uri => 'http://localhost:5984',
    dbname      => 'demouser',
    designdoc   => '_design/user',
    view        => 'user',
    ua          => 'MockLWP',
};

my $store_couchdb = Catalyst::Authentication::Store::CouchDB->new($config);
isa_ok($store_couchdb, 'Catalyst::Authentication::Store::CouchDB');

# sub find_user

my $good_user = $store_couchdb->find_user({ username => 'test' });
ok($good_user, 'User correctly found');
isa_ok($good_user, 'Catalyst::Authentication::Store::CouchDB::User');
my $missing_user = $store_couchdb->find_user({ username => 'testmissing' });
ok(!defined $missing_user, 'Missing user not found');

# sub for_session

my $session_data = $store_couchdb->for_session(undef, $good_user);
is(ref $session_data, '', 'Got a scalar back from for_session');

# sub from_session
my $good_user2 = $store_couchdb->from_session(undef, $session_data);

is($good_user2->id, $good_user->id, 'User from session id matches original');

# sub user_supports

my $supports = $store_couchdb->user_supports();

ok($supports->{roles}, 'Store supports roles');
ok($supports->{session}, 'Store supports session');

# AUTOLOAD

is($good_user->username, 'test', 'AUTOLOAD for username field works');
is($good_user->missing, undef, 'AUTOLOAD for missing field returns undef');


done_testing;
