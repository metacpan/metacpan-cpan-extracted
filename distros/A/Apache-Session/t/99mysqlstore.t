use Test::More;

#plan skip_all => "Not running RDBM tests without APACHE_SESSION_MAINTAINER=1"
#  unless $ENV{APACHE_SESSION_MAINTAINER};
plan skip_all => "Optional modules (DBD::mysql, DBI) not installed"
  unless eval {
               require DBD::mysql;
               require DBI;
              };

plan tests => 2;

my $package = 'Apache::Session::Store::MySQL';
use_ok $package;

my $foo = $package->new;

isa_ok $foo, $package;
