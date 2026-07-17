package TestAppMissingClass;

# Deliberately omits the required 'class' key, to confirm BUILD croaks
# with a helpful message instead of failing silently or obscurely.

use Dancer2;

BEGIN {
   set logger => 'null';
   set plugins => {
      QuickORM => {
         default => {},
      },
   };
}

use Dancer2::Plugin::QuickORM;

1;
