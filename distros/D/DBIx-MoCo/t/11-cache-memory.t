#!perl -T
use strict;
use warnings;
use File::Spec;

use lib File::Spec->catdir('t', 'lib');
use Cache::Memory;
use Blog::Class;

Blog::Class->cache_object(Cache::Memory->new);
ThisTest->runtests;

# ThisTest
package ThisTest;
use base qw/Test::Class/;
use Test::More;
use Blog::User;

sub cache_memory : Tests {
    isa_ok (Blog::Class->cache_object, 'Cache::Memory');
    my $u1 = Blog::User->retrieve(1);
    my $u2 = Blog::User->retrieve(1);
    is_deeply $u2, $u1;
    my $u3 = Blog::User->retrieve_by_name('jkondo');
    is_deeply $u3, $u1;
}

1;
