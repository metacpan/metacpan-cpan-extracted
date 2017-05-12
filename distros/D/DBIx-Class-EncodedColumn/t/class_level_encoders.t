use strict;
use warnings;
use Test::More;

BEGIN {
  if( eval 'require Digest' && eval 'require Digest::SHA' ){
    plan tests => 1;
  } else {
    plan skip_all => 'Digest::SHA not available';
    exit;
  }
}

{
  package TestCorrectlySetClassData;
  use base qw/DBIx::Class/;
  __PACKAGE__->load_components(qw/EncodedColumn Core/);
  __PACKAGE__->table('test_register_column');
}

TestCorrectlySetClassData->add_columns(
  sha1_hex => {
    data_type => 'char',
    is_nullable => 1,
    size      => 40,
    encode_column => 1,
    encode_class  => 'Digest',
    encode_args => {
      format    => 'hex',
      algorithm => 'SHA-1',
    },
    encode_check_method => 'check_sha1_hex',
  },
);
my $encoders_1 = TestCorrectlySetClassData->_column_encoders;

TestCorrectlySetClassData->add_columns(
  sha1_b64 => {
    data_type => 'char',
    is_nullable => 1,
    size      => 27,
    encode_column => 1,
    encode_class  => 'Digest',
    encode_args => {
      algorithm => 'SHA-1',
    },
    encode_check_method => 'check_sha1_b64',
  },
);
my $encoders_2 = TestCorrectlySetClassData->_column_encoders;

isnt($encoders_1, $encoders_2, 'register_column uses fresh ref for econders');
