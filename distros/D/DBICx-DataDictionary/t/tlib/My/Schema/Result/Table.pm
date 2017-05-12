package My::Schema::Result::Table;
our $VERSION = '0.002';

use strict;
use warnings;
use base 'DBIx::Class';

use My::Schema::DataDictionary qw( PK NAME );

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table('table');

__PACKAGE__->add_columns(
  table_id => PK,
  name     => NAME(is_nullable => 1),
);

__PACKAGE__->set_primary_key('table_id');

1;
