# ABSTRACT: a driver storage may extend _dbio_storage_option_names
use strict;
use warnings;

use Test::More;

use DBIO::Storage::DBI;

# A driver that declares its own storage-config connect option. The value is
# consumed by the storage itself (never rendered into SQL, never understood by
# the DBD), so it must land on the storage and must NOT reach DBI->connect.
#
# The two halves a driver has to provide: the name, appended to the inherited
# list, and the accessor that connect_info calls to set it.
{
  package Karr116::Storage;
  use base 'DBIO::Storage::DBI';

  sub _dbio_storage_option_names {
    my $self = shift;
    return ($self->SUPER::_dbio_storage_option_names, 'karr116_option');
  }

  __PACKAGE__->mk_group_accessors('simple' => 'karr116_option');
}

my @conn = ('dbi:Karr116:db=t', 'user', 'pass');

# --- the driver option is routed to the storage ---------------------------
{
  my $storage = Karr116::Storage->new;
  $storage->connect_info([ @conn, {
    karr116_option => 'set-on-storage',
    on_connect_do  => 'SELECT 1',
    quote_char     => '`',
    RaiseError     => 1,
  } ]);

  is $storage->karr116_option, 'set-on-storage',
    'driver-declared storage option is set on the storage';

  my $dbi_attrs = $storage->_dbi_connect_info->[3];
  ok !exists $dbi_attrs->{karr116_option},
    'driver-declared storage option is stripped before DBI->connect';

  # the inherited members of both lists keep behaving as before
  is $storage->on_connect_do, 'SELECT 1', 'inherited storage option still routed';
  ok !exists $dbi_attrs->{on_connect_do}, 'inherited storage option still stripped';
  is $storage->_sql_maker_opts->{quote_char}, '`', 'sql_maker option still routed';
  ok !exists $dbi_attrs->{quote_char}, 'sql_maker option still stripped';
  is $dbi_attrs->{RaiseError}, 1, 'genuine DBI attribute still passed through';
}

# --- control: the base storage does not know the name ---------------------
# Nothing declares karr116_option there, so it is neither a storage option nor
# a DBI attribute by name: the connect info refuses it (karr k327) instead of
# handing it to DBI->connect to be dropped silently. Only the driver's
# declaration makes it a valid option.
{
  my $storage = DBIO::Storage::DBI->new;
  eval { $storage->connect_info([ @conn, { karr116_option => 'set-on-storage' } ]) };
  like $@, qr/Unknown connect attribute\(s\) 'karr116_option'/,
    'undeclared attribute is refused on the base storage';
  ok !$storage->can('karr116_option'),
    'base storage has no accessor for the driver-private option';
}

done_testing;
