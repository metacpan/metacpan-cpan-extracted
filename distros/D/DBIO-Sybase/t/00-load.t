use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::Sybase
  DBIO::Sybase::Storage
  DBIO::Sybase::Storage::ASE
  DBIO::Sybase::Storage::ASE::NoBindVars
  DBIO::Sybase::Storage::FreeTDS
  DBIO::Shortcut::syb
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
