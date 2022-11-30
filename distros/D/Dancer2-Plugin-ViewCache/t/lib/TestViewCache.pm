package TestViewCache;

use Dancer2;
use Dancer2::Plugin::DBIC;

BEGIN {
   set logger => 'null';

   set plugins => {
      'DBIC' => {
         default => {
            schema_class => 'ViewCacheSchema',
            dsn          => 'dbi:SQLite:t/db/test_database.sqlite3',
         }
      },
      'ViewCache' => {
         base_url => 'https://www.site.test',
      }
   };
}

use lib '../lib';
use lib '../../lib';
use Dancer2::Plugin::ViewCache;

set show_errors => 1;
set traces      => 1;

get '/:code?' => sub {
   my $code              = route_parameters->get('code');
   my $delete_after_view = query_parameters->get('delete_after_view');

   my $html = '<body>Hello world!</body>';
   my $res  = generate_guest_url(
      html              => $html,
      code              => $code,
      delete_after_view => $delete_after_view
   );

   return "$res";
};

1;
