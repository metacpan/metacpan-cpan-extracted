use Test2::V0;
use Test::Alien;
use Alien::libswe;
 
alien_ok 'Alien::libswe';

=begin comment
 
xs_ok { local $/; <DATA> }, with_subtest {
  is Foo::something(), 1, 'Foo::something() returns 1';
};

=cut
 
done_testing;
 
__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <foo.h>
 
MODULE = Foo PACKAGE = Foo
 
int something(class)
