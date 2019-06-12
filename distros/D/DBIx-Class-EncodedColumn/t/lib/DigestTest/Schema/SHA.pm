package # hide from PAUSE
    DigestTest::Schema::SHA;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/EncodedColumn Core/);
__PACKAGE__->table('test_sha');
__PACKAGE__->add_columns(
  id => {
    data_type => 'int',
    is_nullable => 0,
    is_auto_increment => 1
  },
  dummy_col => {
    data_type => 'char',
    size      => 43,
    encode_column => 0,
    encode_class  => 'Digest',
    encode_check_method => 'check_dummy_col',
    encode_args => { charset => 'utf-8' },
  },
  sha1_hex => {
    data_type => 'char',
    is_nullable => 1,
    size      => 40,
    encode_column => 1,
    encode_class  => 'Digest',
    encode_args => {
      format    => 'hex',
      algorithm => 'SHA-1',
      charset => 'utf-8',
    },
    encode_check_method => 'check_sha1_hex',
  },
  sha1_b64 => {
    data_type => 'char',
    is_nullable => 1,
    size      => 27,
    encode_column => 1,
    encode_class  => 'Digest',
    encode_args => {
      algorithm => 'SHA-1',
      charset => 'utf-8',
    },
    encode_check_method => 'check_sha1_b64',
  },
  sha256_hex => {
    data_type => 'char',
    is_nullable => 1,
    size      => 64,
    encode_column => 1,
    encode_class  => 'Digest',
    encode_args => { format => 'hex', charset => 'utf-8', },
  },
  sha256_b64 => {
    data_type => 'char',
    is_nullable => 1,
    size      => 43,
    accessor  => 'sha256b64',
    encode_column => 1,
    encode_class  => 'Digest',
    encode_args => { charset => 'utf-8' },
  },
  sha256_b64_salted => {
    data_type => 'char',
    is_nullable => 1,
    size      => 57,
    encode_column => 1,
    encode_class  => 'Digest',
    encode_check_method => 'check_sha256_b64_salted',
    encode_args   => {salt_length => 14, charset => 'utf-8', }
  },
);

__PACKAGE__->set_primary_key('id');

1;
