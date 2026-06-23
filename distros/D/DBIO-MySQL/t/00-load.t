use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::MySQL
  DBIO::MySQL::Storage
  DBIO::MySQL::MariaDB
  DBIO::MySQL::Storage::MariaDB
  DBIO::MySQL::SQLMaker
  DBIO::MySQL::SQLMaker::MariaDB
  DBIO::MySQL::Result
  DBIO::MySQL::Introspect
  DBIO::Shortcut::mysql
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
