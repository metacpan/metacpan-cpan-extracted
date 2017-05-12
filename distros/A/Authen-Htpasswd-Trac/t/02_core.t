#!/perl

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 13;

use Authen::Htpasswd::Trac;
use File::Spec::Functions;

my $file = Authen::Htpasswd::Trac->new(catfile(qw/t data passwd.txt/), { trac => catfile(qw/t data trac.db/)});

ok( $file, 'object created successfully');

ok( $file->check_user_password(qw/ joe secret /), 'plaintext password verified' );
ok( !$file->check_user_password(qw/ joe tersec /), 'incorrect plaintext password rejected' );

ok( $file->check_user_password(qw/ bob margle /), 'crypt password verified' );
ok( !$file->check_user_password(qw/ bob foogle /), 'incorrect crypt password rejected' );

SKIP: {
    skip "Crypt::PasswdMD5 is required for md5 passwords", 2 unless grep { $_ eq 'md5' } @{$file->check_hashes};
    ok( $file->check_user_password(qw/ bill blargle /), 'md5 password verified' );
    ok( !$file->check_user_password(qw/ bill fnord /), 'incorrect md5 password rejected' );
}

SKIP: {
    skip "Digest::SHA1 is required for md5 passwords", 2 unless grep { $_ eq 'sha1' } @{$file->check_hashes};
    ok( $file->check_user_password(qw/ fred fribble /), 'sha1 password verified' );
    ok( !$file->check_user_password(qw/ fred frobble /), 'incorrect sha1 password rejected' );
}

$file->check_hashes([qw/ crypt /]);
ok( !$file->check_user_password(qw/ joe secret /), 'correct plaintext password denied');

my @users = $file->all_users;
is( scalar @users, 4, 'returned correct number of users' );
is( $users[0]->username, 'bob', 'first user has right name' );
is( $users[-1]->username, 'joe', 'last user has right name' );
