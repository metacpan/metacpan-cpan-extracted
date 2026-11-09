use strict;
use warnings;
use Test::More;

# The modules load with only core DBIO + core Perl present.
use_ok('DBIO::Forked');
use_ok('DBIO::Forked::Storage');
use_ok('DBIO::Forked::Future');

# Core contract class, used to validate the Future below.
use_ok('DBIO::Future');

# Storage satisfies the core async-storage contract.
ok(
  DBIO::Forked::Storage->isa('DBIO::Storage::Async'),
  'DBIO::Forked::Storage isa DBIO::Storage::Async',
);

# future_class points at our loop-free Future.
is(
  DBIO::Forked::Storage->future_class,
  'DBIO::Forked::Future',
  'future_class returns DBIO::Forked::Future',
);

# Activation wiring: new($schema) + connect_info(DBI-form) must not croak,
# and connect_info answers the form of the DBI-form arrayref (t/13).
my $storage = DBIO::Forked::Storage->new(undef);
isa_ok($storage, 'DBIO::Forked::Storage');

my $conninfo = [ 'dbi:SQLite:dbname=:memory:', '', '', { AutoCommit => 1 } ];
is_deeply(
  $storage->connect_info($conninfo),
  { broker => 0, elements => 4 },
  'connect_info keeps and returns the form of the DBI-form connect info',
);

# DBIO::Forked::Future fulfils the core DBIO::Future contract
# (then / catch / get / is_ready / is_failed all present).
my $future = DBIO::Forked::Future->new;
ok(
  DBIO::Future->validate($future),
  'DBIO::Forked::Future satisfies the DBIO::Future contract',
);

done_testing;
