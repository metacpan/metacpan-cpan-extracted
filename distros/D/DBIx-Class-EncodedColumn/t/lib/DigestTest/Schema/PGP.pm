package # hide from PAUSE
  DigestTest::Schema::PGP;

use strict;
use warnings;
use base qw/DBIx::Class/;
use Dir::Self;
use File::Spec;

my $pgp_conf = {
  SecRing => File::Spec->catdir(__DIR__,'secring.gpg'),
  PubRing => File::Spec->catdir(__DIR__,'pubring.gpg'),
};

__PACKAGE__->load_components(qw/EncodedColumn Core/);
__PACKAGE__->table('test_pgp');
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
  },
  pgp_col_passphrase => {
    data_type => 'text',
    is_nullable => 1,
    encode_column => 1,
    encode_class  => 'Crypt::OpenPGP',
    encode_args => {
      passphrase => 'Secret Words',
      armour     => 1
    },
    encode_check_method => 'decrypt_pgp_passphrase',
  },
  pgp_col_key => {
    data_type => 'text',
    is_nullable => 1,
    encode_column => 1,
    encode_class  => 'Crypt::OpenPGP',
    encode_args => {
      recipient => '1B8924AA',
      pgp_args   => $pgp_conf,
      armour     => 1
    },
    encode_check_method => 'decrypt_pgp_key',
  },
  pgp_col_key_ps => {
    data_type => 'text',
    is_nullable => 1,
    encode_column => 1,
    encode_class  => 'Crypt::OpenPGP',
    encode_args => {
      recipient => '7BEF6294',
      pgp_args   => $pgp_conf,
      armour     => 1
    },
    encode_check_method => 'decrypt_pgp_key_ps',
  },
  pgp_col_rijndael256 => {
    data_type => 'text',
    is_nullable => 1,
    encode_column => 1,
    encode_class  => 'Crypt::OpenPGP',
    encode_args => {
      passphrase => 'Secret Words',
      armour     => 1,
      pgp_args   => $pgp_conf,
      cipher     => 'Rijndael256',
    },
    encode_check_method => 'decrypt_pgp_rijndael256',
  },
);

__PACKAGE__->set_primary_key('id');

1;
