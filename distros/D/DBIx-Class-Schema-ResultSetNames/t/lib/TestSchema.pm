package TestSchema;

use strict;
use warnings;
use base qw(DBIx::Class::Schema);

__PACKAGE__->load_components('Schema::ResultSetNames');

__PACKAGE__->load_namespaces;

sub override_rsnames {
   return { 'Widget' => { singular => 'block', plural => 'clocks' } };
}

1;
