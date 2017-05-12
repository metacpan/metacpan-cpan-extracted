#!perl -T
use strict;
use warnings;
use File::Spec;

use lib File::Spec->catdir('t', 'lib');

ThisTest->runtests;

# ThisTest
package ThisTest;
use base qw/Test::Class/;
use Test::More;
use DBIx::MoCo;
use Blog::User;
use Blog::Bookmark;
use Blog::Entry;
use Data::Dumper;

sub param : Tests {
    my $u = Blog::User->retrieve(1);
    ok (DBIx::MoCo->is_in_session);
    my $name = $u->name;
    ok $name;
    $u->name('jkontan');
    is $u->name, 'jkontan';
    isnt $u->name, $name;
    ok ($u->{to_be_updated});
    my ($u2) = Blog::User->search(where => {user_id => 1});
    ok $u2;
    is $u2->name, $name;
    isnt $u2->name, $u->name;
    $u->save;
    is $u->name, 'jkontan';
    ok (!$u->{to_be_updated});
    my ($u3) = Blog::User->search(where => {user_id => 1});
    is $u3->name, 'jkontan';
}

sub start_session : Test(setup) {
    DBIx::MoCo->start_session;
}

sub session : Tests {
    my $s = DBIx::MoCo->session;
    ok $s;
    isa_ok $s->{changed_objects}, 'ARRAY';
    ok (DBIx::MoCo->is_in_session);
}

sub end_session : Tests {
    DBIx::MoCo->end_session;
    ok (!DBIx::MoCo->session);
    ok (!DBIx::MoCo->is_in_session);
    DBIx::MoCo->start_session;
}

sub create : Tests {
    my $u = Blog::User->create(
        user_id => 7,
        name => 'lucky7',
    );
    ok $u;
    is $u->user_id, 7;
    is $u->name, 'lucky7';
    my ($u2) = Blog::User->search(where => {user_id =>7});
    # ok (!$u2);
    ok ($u2);
    $u->name('lucky lucky 7');
    is $u->name, 'lucky lucky 7';
    my ($u3) = Blog::User->search(where => {user_id =>7});
    # ok (!$u3);
    ok ($u3);
    DBIx::MoCo->end_session;
    DBIx::MoCo->start_session;
    $u->store_self_cache;
    my ($u4) = Blog::User->search(where => {user_id =>7});
    ok ($u4);
    is $u4->user_id, 7;
    is $u4->name, 'lucky lucky 7';
    my $u5 = Blog::User->retrieve(7);
    is $u5->name, $u->name;
}

1;
