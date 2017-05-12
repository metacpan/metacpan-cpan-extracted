package # hide from PAUSE 
    DigestTest::Schema::Test;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/DigestColumns PK::Auto Core/);
__PACKAGE__->table('test');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'int',
    is_nullable	=> 0,
    is_auto_increment => 1,
  },
  'password' => {
    data_type => 'varchar',
    size      => 100,
    digest_check_method => 'check_password',
  }
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->digest_columns('password');

1;
