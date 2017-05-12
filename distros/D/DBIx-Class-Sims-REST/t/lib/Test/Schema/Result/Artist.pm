package Test::Schema::Result::Artist;

use 5.010_000;

use strict;
use warnings FATAL => 'all';

use base 'DBIx::Class::Core';

__PACKAGE__->table('artists');
__PACKAGE__->add_columns(
  id => {
    data_type => 'int',
    is_nullable => 0,
    is_auto_increment => 1,
  },
  name => {
    data_type => 'varchar',
    size => 128,
    is_nullable => 0,
  },
  hat_color => {
    data_type => 'varchar',
    size => 128,
    is_nullable => 1,
    sim => { value => 'purple' },
  },
);
__PACKAGE__->set_primary_key('id');

1;
__END__
