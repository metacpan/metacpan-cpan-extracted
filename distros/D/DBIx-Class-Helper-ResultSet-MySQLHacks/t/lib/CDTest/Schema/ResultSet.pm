use utf8;
package # hide from PAUSE
    CDTest::Schema::ResultSet;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::MySQLHacks');

1;
