use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;
use DBIO::Test::Storage ();
use DBIO::Storage::DBI::Capabilities ();

# Asking for a capability as a class method is legal only as long as
# somebody has declared the answer at class level via _use_. As soon as the
# value has to be *determined*, the probe reads the connected $dbh and needs a
# real storage instance -- and the bare accessor died there with
# "Class::XSAccessor: invalid instance method invocant: no hash ref supplied",
# which names neither the capability nor the reason.
#
# The behaviour is deliberately unchanged (determination still requires an
# instance; asking a live storage is the more meaningful assertion anyway).
# This file pins the diagnosis.

my $schema = DBIO::Test->init_schema;

# --- 1. determination as a class method: the message must be about
#        capabilities, not about hash refs ----------------------------------

throws_ok {
  DBIO::Test::Storage->_use_supports_upsert_where;
} qr/_supports_supports_upsert_where/,
  'a class-method capability probe names the capability it could not determine';

my $err = $@;

unlike "$err", qr/XSAccessor|hash ref/i,
  'the raw Class::XSAccessor complaint no longer leaks to the caller';

like "$err", qr/storage instance/i,
  'the message says a storage instance is what is missing';

like "$err", qr/_use_supports_upsert_where/,
  'the message names the _use_ override that would answer at class level';

isa_ok $err, 'DBIO::Exception',
  'it is a typed DBIO::Exception';

# the same holds for the _supports_ tier, which is where the probe actually
# lives -- reaching it directly from a class must not die differently
throws_ok {
  DBIO::Test::Storage->_supports_transactional_ddl;
} qr/_supports_transactional_ddl/,
  'the _supports_ tier throws the same capability-named exception';

unlike "$@", qr/XSAccessor|hash ref/i,
  '... and does not leak the accessor internals either';

# --- 2. a capability declared at class level still answers as a class
#        method (this is the part that made the failure look arbitrary) ------

{
  package DBIO::Test::CapClassMethod::Declared;
  our @ISA = ('DBIO::Test::Storage');
  __PACKAGE__->_use_supports_upsert(1);
  __PACKAGE__->_use_supports_upsert_where(0);
}

is( DBIO::Test::CapClassMethod::Declared->_use_supports_upsert, 1,
  'an explicitly declared _use_ capability still answers as a class method' );

is( DBIO::Test::CapClassMethod::Declared->_use_supports_upsert_where, 0,
  'an explicit 0 answers as a class method too, it is not "unset"' );

# ... while its undeclared neighbour on the very same class still needs an
# instance -- the asymmetry the ticket is about, now with a message that
# explains itself
throws_ok {
  DBIO::Test::CapClassMethod::Declared->_use_supports_if_exists;
} qr/_supports_supports_if_exists/,
  'an undeclared neighbour on the same class explains why it cannot answer';

# --- 3. instance behaviour is untouched -----------------------------------

{
  my $storage = $schema->storage;

  is $storage->_use_supports_upsert_where, 0,
    'an instance determines the capability as before';

  is $storage->_supports_transactional_ddl, 0,
    'the _supports_ tier determines on an instance as before';

  $storage->_use_supports_upsert_where(1);
  is $storage->_use_supports_upsert_where, 1,
    'setting _use_ on an instance is honoured as before';
}

# join_optimizer is declared on the base class itself, so it is the one
# capability that has always answered as a class method -- it must keep doing so
is( DBIO::Storage::DBI::Capabilities->_use_join_optimizer, 1,
  'the base-class declaration of join_optimizer still answers as a class method' );

done_testing;
