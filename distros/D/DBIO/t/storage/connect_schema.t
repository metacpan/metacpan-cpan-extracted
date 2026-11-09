# ABSTRACT: the generic connect key 'schema' names the connection's namespace (karr k336)
use strict;
use warnings;

use Test::More;

use DBIO::Storage::DBI;
use DBIO::Storage::Async;

# CLAIM: 'schema' is one generic connect key. Core owns the word and the
# contract -- a plain name, stripped from DBI->connect, kept on the storage
# under connection_schema (the accessor 'schema' is the storage's back-reference
# to the DBIO schema class and must stay that) -- and a driver gives it meaning
# through _set_connection_schema. A storage whose driver does not override that
# seam refuses loudly; the key never decides the driver.

my @conn = ('dbi:Karr336:db=t', 'user', 'pass');

{
  package Karr336::Driver;
  use base 'DBIO::Storage::DBI';
  our @LOG;
  sub _set_connection_schema { push @LOG, "SET SCHEMA $_[1]" }
  sub connect_call_rec { push @LOG, 'on_connect_call' }
}
{
  package Karr336::FakeSchemaClass;
  sub throw_exception { shift; die @_ }
}

# --- routed to connection_schema, not to the back-reference ----------------
{
  my $marker = bless {}, 'Karr336::FakeSchemaClass';
  my $storage = Karr336::Driver->new($marker);
  $storage->connect_info([ @conn, { schema => 'tenant_a', RaiseError => 1 } ]);

  is $storage->connection_schema, 'tenant_a', 'schema key lands on connection_schema';
  is $storage->schema, $marker, 'the schema back-reference accessor is untouched';
  ok !exists $storage->_dbi_connect_info->[3]{schema}, 'schema never reaches DBI->connect';
  is $storage->_dbi_connect_info->[3]{RaiseError}, 1, 'real DBI attributes still pass';
}

# --- connect_info is a full reconfiguration (ADR 0050) ---------------------
{
  my $storage = Karr336::Driver->new;
  $storage->connect_info([ @conn, { schema => 'tenant_a' } ]);
  $storage->connect_info([ @conn ]);
  ok !defined $storage->connection_schema, 'a later connect_info without schema resets it';
}

# --- only a plain name -----------------------------------------------------
for my $bad ([ 'a', 'b' ], { a => 1 }, '', undef) {
  my $storage = Karr336::Driver->new;
  eval { $storage->connect_info([ @conn, { schema => $bad } ]) };
  like $@, qr/connect key 'schema' takes a single non-empty name/,
    'schema value ' . (defined $bad ? (ref $bad || "'$bad'") : 'undef') . ' is refused';
}

# --- a driver without namespaces refuses loudly ----------------------------
{
  my $storage = DBIO::Storage::DBI->new;
  $storage->connect_info([ @conn, { schema => 'tenant_a' } ]);
  eval { $storage->_run_connection_actions };
  like $@, qr/DBIO::Storage::DBI has no namespaces.*'schema'/s,
    'default seam refuses, naming the storage class';
  isa_ok $@, 'DBIO::Exception';

  my $none = DBIO::Storage::DBI->new;
  $none->connect_info([ @conn ]);
  eval { $none->_run_connection_actions };
  is $@, '', 'no schema given: the seam is never asked';
}

# --- sync connect: the driver seam runs before the user's own actions ------
{
  @Karr336::Driver::LOG = ();
  my $storage = Karr336::Driver->new;
  $storage->connect_info([ @conn, { schema => 'tenant_a', on_connect_call => 'rec' } ]);
  $storage->_run_connection_actions;
  is_deeply \@Karr336::Driver::LOG, [ 'SET SCHEMA tenant_a', 'on_connect_call' ],
    'seam asked once with the name, before on_connect_call';
}

# --- async pool connection: same seam, on the pool connection --------------
{
  @Karr336::Driver::LOG = ();
  my $storage = Karr336::Driver->new;
  $storage->connect_info([ @conn, { schema => 'tenant_b' } ]);
  $storage->_run_pool_connect_actions(sub { push @Karr336::Driver::LOG, 'runner' });
  is_deeply \@Karr336::Driver::LOG, [ 'SET SCHEMA tenant_b' ],
    'pool connection replay asks the same seam';
}

# --- async strip keeps the key out of the transport's conninfo -------------
{
  my $async = DBIO::Storage::Async->new;
  my $out = $async->_strip_private_connect_attrs([ @conn, { schema => 'tenant_a', RaiseError => 1 } ]);
  ok !exists $out->[3]{schema}, 'async strip removes schema from the DBD attributes';
  is $out->[3]{RaiseError}, 1, 'async strip keeps real attributes';
  is $async->{_storage_options}{schema}, 'tenant_a', 'async strip keeps it with the storage options';
}

# --- the key names no driver ------------------------------------------------
{
  my $storage = DBIO::Storage::DBI->new;
  $storage->connect_info([ @conn, { schema => 'x' } ]);
  is ref $storage, 'DBIO::Storage::DBI', 'schema key does not rebless or pick a driver';
}

done_testing;
