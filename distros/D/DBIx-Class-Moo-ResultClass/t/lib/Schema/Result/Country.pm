package Schema::Result::Country;

use base qw(Schema::Result);
use DBIx::Class::Moo::ResultClass;

with 'Component';

has spork => (is => 'ro', default => sub { 'THERE IS NO SPROK' });

__PACKAGE__->table('country');

__PACKAGE__->add_columns(
  country_id => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  name => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('country_id');

1;
