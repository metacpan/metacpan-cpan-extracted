use 5.20.0;
use strict;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::ResultSet::Country;

our $VERSION = '0.0001';

use TestFor::DBIx::Class::Smooth::Schema::ResultSet -components => [qw/
/];
use DBIx::Class::Smooth::Q;

sub annotate_get($self, $column_name, $structure, $id = 1) {
    return $self->annotate($column_name => $structure)->filter(id => $id)->first->get_column($column_name);
}

1;
