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
use Blog::User;

sub add_trigger : Test(startup) {
    Blog::User->add_trigger('before_create', sub {
        my ($class, $args) = @_;
        $args->{name} .= '-san';
    });
}

sub retrieve_null : Tests {
    my $u = Blog::User->create(name => 'ishizaki');
    ok ($u, 'create user');
    is ($u->name, 'ishizaki-san', 'user name');
}

1;
