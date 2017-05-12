package # hide from PAUSE
   test::Schema::Result::User;

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components(qw/Validation::Structure/);

__PACKAGE__->table('user');
__PACKAGE__->add_columns(
      'id' => {
         data_type => 'integer',
         is_auto_increment => 1,
      },
      'email' => {
         data_type => 'varchar',
         size => '128',
         val_override => 'email',
      },
      'first_name' => {
         data_type => 'varchar',
         size => '32',
      },
      'middle_name' => {
         data_type => 'varchar',
         size => '32',
         is_nullable => 1,
      },
      'last_name' => {
         data_type => 'varchar',
         size => '128',
      },
      'suffix' => {
         data_type => 'varchar',
         size => '32',
         is_nullable => 1,
      },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint([ qw/email/ ]);
__PACKAGE__->add_unique_constraints(
  'itscomplicated' => [ qw/first_name middle_name last_name/ ],
  'overlapping' => [ qw/last_name suffix/ ],
);

# -------- Relationships --------

# -------- Helper functions --------
1;
