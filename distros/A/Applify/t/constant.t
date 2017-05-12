use strict;
use warnings;
use Test::More;

my $app = eval q[
  use Applify;
  use constant FOO => 123;
  sub foo { 123 }
  app { return 0; };
];

is $@, '', 'use constant works';
ok $app, 'app was contstructed';
is $app->foo, 123, 'foo() return 123' if $app;

done_testing;
