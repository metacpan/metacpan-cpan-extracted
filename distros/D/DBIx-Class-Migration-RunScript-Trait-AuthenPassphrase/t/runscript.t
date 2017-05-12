#!/usr/bin/env perl

use lib 't/lib';
use Test::Most;
use DBIx::Class::Migration;
use DBIx::Class::Migration::RunScript;
use DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase;
use File::Spec::Functions 'catfile';
use File::Path 'rmtree';

ok(
  my $migration = DBIx::Class::Migration->new(schema_class=>'Local::Schema'),
  'created migration with schema_class');

$migration->prepare;
$migration->install;

my $code = migrate {
  my $runscript = shift;
  ok $runscript->can('authen_passphrase'), 'Got authen_passphrase';

  my $password = 'plaintext';
  my $args = {
    passphrase => 'rfc2307',
    passphrase_class => 'SaltedDigest',
    passphrase_args => {
      algorithm => 'SHA-1',
      salt_random => 20,
    },
  };

  ok my $encoded = $runscript->authen_passphrase($args, $password),
    'got an encoded string';

  ok $runscript->schema->resultset('Artist')->create({
    name => 'John',
    passphrase => $encoded,
    country_fk => {code=>'AAA'}});
};
  
ok $code->($migration->schema, [1,2]);
ok my $artist = $migration->schema->resultset('Artist')->first;
ok $artist->check_passphrase('plaintext'), 'password checked';
ok ! $artist->check_passphrase('NOTPASSWORD'), 'password invalid';

done_testing;

END {
  rmtree catfile($migration->target_dir, 'migrations');
  rmtree catfile($migration->target_dir, 'fixtures');
  unlink catfile($migration->target_dir, 'local-schema.db');
}
