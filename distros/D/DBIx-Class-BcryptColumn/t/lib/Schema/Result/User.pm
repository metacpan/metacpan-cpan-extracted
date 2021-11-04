package Schema::Result::User;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->load_components('BcryptColumn');
 
__PACKAGE__->table('user');

__PACKAGE__->add_columns(
  id => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  name => {
    data_type => 'varchar',
    size => '96',
  },
  password => {
    data_type => 'varchar',
    size => '96',
    bcrypt => 1,
  },
);

__PACKAGE__->set_primary_key('id');

1;
