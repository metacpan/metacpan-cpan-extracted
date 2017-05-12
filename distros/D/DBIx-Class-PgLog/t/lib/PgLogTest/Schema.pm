use utf8;
package PgLogTest::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-07-11 14:35:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2dVssnEknhZ6t1YX6zNbHg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->load_components(qw/Schema::PgLog/);

#__PACKAGE__->load_namespaces(default_resultset_class => "+DBIx::Class::ResultSet::PgLog");

1;
