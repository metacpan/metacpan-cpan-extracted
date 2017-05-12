package # hide from PAUSE
    DigestTest::Schema::Whirlpool;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/EncodedColumn Core/);
__PACKAGE__->table('test_whirlpool');
__PACKAGE__->add_columns(
  id => {
    data_type => 'int',
    is_nullable => 0,
    is_auto_increment => 1
  },
  whirlpool_hex => {
    data_type => 'char',
    is_nullable => 1,
    size => 128,
    encode_column => 1,
    encode_class  => 'Digest',
    encode_args   => {
      format => 'hex',
      algorithm => 'Whirlpool',
    },
    encode_check_method => 'check_whirlpool_hex',
  },
  whirlpool_b64 => {
    data_type => 'char',
    is_nullable => 1,
    size => 86,
    encode_column => 1,
    encode_class  => 'Digest',
    encode_args   => {
      algorithm => 'Whirlpool',
    },
    encode_check_method => 'check_whirlpool_b64',
  },
);

__PACKAGE__->set_primary_key('id');

1;
