package # hide from PAUSE
    Schema::Result::Argon2;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(EncodedColumn Core));
__PACKAGE__->table('argon2');
__PACKAGE__->add_columns(
  id => {
    data_type         => 'int',
    is_nullable       => 0,
    is_auto_increment => 1
  },
  argon2_1 => {
    data_type           => 'text',
    is_nullable         => 1,
    size                => 60,
    encode_column       => 1,
    encode_class        => 'Crypt::Passphrase::Argon2',
    encode_check_method => 'argon2_1_check',
  },
  argon2_2 => {
    data_type           => 'text',
    is_nullable         => 1,
    size                => 59,
    encode_column       => 1,
    encode_class        => 'Crypt::Passphrase::Argon2',
    encode_args         => {},
    encode_check_method => 'argon2_2_check',
  },
);

__PACKAGE__->set_primary_key('id');

1;
