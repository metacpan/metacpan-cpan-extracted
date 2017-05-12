use strict;
use warnings;
use Test::More;
use Try::Tiny;

use lib 't/lib', 't/lib2';

$SIG{__WARN__} = sub { die @_ if $_[0] =~ /Deep recursion/; warn @_; };

try {
   require IRC::Schema::Result::User;
   require IRC::Schema::Result::Message;
   require IRC::Schema::Result::Foo;
   require IRC::Schema::Result::Bar;
} catch {
   ok($_ !~ m/Deep recursion/, q(didn't deeply recurse))
};

pass('did not crater perl');

done_testing;
