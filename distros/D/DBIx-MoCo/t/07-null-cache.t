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

sub retrieve_null : Tests {
    my $name = 'no_one_in_the_world';
    my $u1 = Blog::User->retrieve(name => $name);
    ok (!$u1, 'retrieve null');
    my $u2 = Blog::User->create(name => $name);
    ok ($u2, 'create u2');
    my $u3 = Blog::User->retrieve(name => $name);
    ok ($u3, 'retrieve u3');
    is_deeply ($u3, $u2, 'u3 is u2');
}

1;
