package Test::Schema::Result::Example;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('examples');
__PACKAGE__->load_components(qw/ InflateColumn::TimeMoment /);

__PACKAGE__->add_columns(
    'id' => { data_type => 'integer', },
    'dt' => { data_type => 'datetime', datetime_undef_if_invalid => 1 },
);

__PACKAGE__->set_primary_key('id');

1;
