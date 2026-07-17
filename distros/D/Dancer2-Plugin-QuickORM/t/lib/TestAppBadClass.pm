package TestAppBadClass;

# References an ORM class that doesn't exist, to confirm BUILD croaks
# with a helpful message rather than a raw, confusing require() failure.

use Dancer2;

BEGIN {
   set logger => 'null';
   set plugins => {
      QuickORM => {
         default => { class => 'This::Class::Does::Not::Exist' },
      },
   };
}

use Dancer2::Plugin::QuickORM;

1;
