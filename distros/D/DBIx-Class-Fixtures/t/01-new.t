#!perl

use DBIx::Class::Fixtures;
use Test::More tests => 3;
use Test::TempDir::Tiny;
use IO::All;

my $tempdir = tempdir;

my $config_dir = io->catfile(qw't var configs')->name;
my $imaginary_config_dir = io->catfile(qw't var not_there')->name;

eval {
  DBIx::Class::Fixtures->new({ });
};
ok($@, 'new errors without config dir');

eval {
  DBIx::Class::Fixtures->new({ config_dir => $imaginary_config_dir });
};
ok($@, 'new errors with non-existent config dir');

ok(my $fixtures = DBIx::Class::Fixtures->new({ config_dir => $config_dir }), 'object created with correct config dir');

