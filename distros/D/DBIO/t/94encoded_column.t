use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;

{
  package TestDBIO::Encoded::Schema;
  use base 'DBIO::Schema';
}

{
  package TestDBIO::Encoded::Schema::Result::User;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/EncodedColumn/);

  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_auto_increment => 1,
    },
    password => {
      data_type           => 'varchar',
      size                => 255,
      is_nullable         => 1,
      encode_column       => 1,
      encode_check_method => 'check_password',
      encode_args         => {
        algorithm   => 'SHA-256',
        salt_length => 8,
      },
    },
  );
  __PACKAGE__->set_primary_key('id');
}

TestDBIO::Encoded::Schema->register_class(User => 'TestDBIO::Encoded::Schema::Result::User');

my $schema = TestDBIO::Encoded::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));

my $user = $schema->resultset('User')->new_result({ password => 's3cret' });

my $encoded = $user->get_column('password');
unlike($encoded, qr/\As3cret\z/, 'password is encoded, not stored plaintext');
like($encoded, qr/\Adbio\$SHA-256\$[^\$]*\$[^\$]+\z/, 'password uses DBIO encoded format');

is($user->get_column('password'), $encoded, 'encoded value is stable across repeated reads');

ok($user->check_password('s3cret'), 'check_password accepts the correct value');
ok(!$user->check_password('wrong'), 'check_password rejects an invalid value');

my $second = $schema->resultset('User')->new_result({ password => 's3cret' });
my $second_encoded = $second->get_column('password');
isnt($second_encoded, $encoded, 'salting generates different hashes for same plaintext');

$user->password($encoded);
is($user->get_column('password'), $encoded, 'pre-encoded values are not re-encoded');

$user->password(undef);
ok(!defined $user->get_column('password'), 'undef values remain undef');

ok(!$user->check_password('s3cret'), 'check_password returns false when column is undef');

done_testing;
