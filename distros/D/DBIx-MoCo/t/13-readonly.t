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
use Blog::ReadonlyUser;

sub use_test : Tests {
    use_ok 'Blog::ReadonlyUser';
}

sub retrieve : Tests {
    my $u = Blog::ReadonlyUser->retrieve(1);
    ok $u;
    is $u->user_id, 1;
    is $u->name, 'jkondo';
}

sub create : Tests {
    eval {Blog::ReadonlyUser->create(
        user_id => 16,
        name => 'jkontan',
    )};
    ok $@;
}

sub delete : Tests {
    my $u = Blog::ReadonlyUser->retrieve(1);
    ok $u;
    eval { $u->delete };
    ok $@;
}

sub param : Tests {
    my $u = Blog::ReadonlyUser->retrieve(1);
    ok $u;
    my $name = $u->name;
    eval { $u->param(name => 'John') };
    ok $@;
    is $u->name, $name;
}

1;
