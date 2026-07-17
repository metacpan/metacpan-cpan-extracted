use strict;
use warnings;
use lib 't/lib';
use Test2::V0;

subtest 'a missing "class" key croaks with a helpful message' => sub {
   plan tests => 1;

   my $ok = eval { require TestAppMissingClass; 1 };
   like(
      $@,
      qr/ORM 'default' is missing 'class' in the configuration/,
      'BUILD refuses to start without a class'
   );
};

subtest 'an unloadable "class" croaks with a helpful message' => sub {
   plan tests => 1;

   my $ok = eval { require TestAppBadClass; 1 };
   like(
      $@,
      qr/Failed to load ORM class 'This::Class::Does::Not::Exist'/,
      'BUILD refuses to start with a class that fails to load'
   );
};

done_testing;
