use utf8;
package Sample::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-13 13:30:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EaqX6pArxiT0GUiQ9UD3jQ

sub test_schema {
    my $class = shift;
    return $class->connect('dbi:SQLite:dbname=data/orders.db');
}

1;
