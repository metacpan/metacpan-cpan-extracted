#!/perl

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 28;

use Authen::Htpasswd::Trac;
use File::Spec::Functions;

use File::Copy;
copy(catfile(qw/t data passwd.txt/), catfile(qw/t data temp.txt/)) or die $!;

my $file = Authen::Htpasswd::Trac->new(catfile(qw/t data temp.txt/), {trac => catfile(qw/t data trac.db/)});

ok( $file, 'object created successfully');

ok( $file->add_user(qw/ jim frobnicate /), 'new user created' );
ok( $file->check_user_password(qw/ jim frobnicate /), 'new user verified' );

ok( $file->update_user(qw/ fred frobble /), 'user updated' );
ok( $file->check_user_password(qw/ fred frobble /), 'updated user verified' );
ok( !$file->check_user_password(qw/ fred fribble /), 'old password invalid' );

ok( $file->delete_user('jim'), 'deleted user' );
eval { $file->check_user_password(qw/ jim frobnicate /) };
ok( $@, 'deleted user not found' );

my $user = $file->lookup_user('bob');

ok( $user, 'looked up user' );
ok( $user->check_password('margle'), 'verified password' );

ok( $user->password('farble'), 'changed password');
$user = $file->lookup_user('bob');
ok( $user->check_password('farble'), 'verified changed password');

is(scalar @{$user->extra_info}, 2, 'extra info has two fields');
is( $user->extra_info->[0], 'admin', 'verified first field of extra info' );
is( $user->extra_info->[1], 'bob@universe.org', 'verified second field extra info' );

is(scalar @{$user->extra_info}, 2, 'extra info still has two fields');
is( $user->extra_info->[0], 'admin', 'info not clobbered');

ok( $user->extra_info('janitor'), 'changed extra info');
$user = $file->lookup_user('bob');
is(scalar @{$user->extra_info}, 1, 'extra info reduced to one field');
is( $user->extra_info->[0], 'janitor', 'verified extra info');

ok( $user->set( username => 'fred', password => 'orange', extra_info => [qw/ gray black /] ), 'set multiple fields' );
ok( !$file->lookup_user('bob'), 'old name of user not found' );
$user = $file->lookup_user('fred');
ok( $user, 'new name of user found');

is( $user->username, 'fred', 'user has correct username');
ok( $user->check_password('orange'), 'user has correct password');
is(scalar @{$user->extra_info}, 2, 'extra info has two fields');

eval { $user->password() };
ok($@, 'password with no args dies');
ok($user->check_password('orange'), 'user still has correct password');

unlink catfile(qw/t data temp.txt/);

