package TestSchema::Result::Widget;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('widget');
__PACKAGE__->add_columns(qw(id created_at SKU));
__PACKAGE__->set_primary_key('id');



1;
