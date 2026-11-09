# ABSTRACT: a second connect_info() call resets unnamed storage options (ADR 0050)
use strict;
use warnings;

use Test::More;

use DBIO::Storage::DBI;

# ADR 0050: connect_info() is a full reconfiguration, not a merge. A storage
# option not named in a given call must revert to its default BEFORE that
# call's options are applied -- symmetric with the sql_maker wipe a few lines
# below it in the real code. cursor_class is the one exception: it resets to
# its class default, never undef.
{
  package Karr197::Storage;
  use base 'DBIO::Storage::DBI';

  sub _dbio_storage_option_names {
    my $self = shift;
    return ($self->SUPER::_dbio_storage_option_names, 'karr197_option');
  }

  __PACKAGE__->mk_group_accessors('simple' => 'karr197_option');
}

{
  package Karr197::Cursor;
  use base 'DBIO::Storage::DBI::Cursor';
}

my @conn = ('dbi:Karr197:db=t', 'user', 'pass');

my $storage = Karr197::Storage->new;

# --- first call: set everything ------------------------------------------
$storage->connect_info([ @conn, {
  on_connect_do  => 'SELECT 1',
  karr197_option => 'set-on-first-call',
  cursor_class   => 'Karr197::Cursor',
} ]);

is $storage->on_connect_do, 'SELECT 1', 'on_connect_do set on first call';
is $storage->karr197_option, 'set-on-first-call',
  'driver-extended storage option set on first call';
is $storage->cursor_class, 'Karr197::Cursor', 'cursor_class set on first call';

# --- second call: omits all three, but names a positive control ----------
$storage->connect_info([ @conn, {
  quote_char => '`', # positive control: named options are still applied
} ]);

is $storage->on_connect_do, undef,
  'on_connect_do from the first call no longer active after a second connect_info (ADR 0050)';

is $storage->karr197_option, undef,
  'driver-extended storage option from the first call is cleared too';

is $storage->cursor_class, 'DBIO::Storage::DBI::Cursor',
  'cursor_class reverts to its class default, not undef';

is $storage->_sql_maker_opts->{quote_char}, '`',
  'an option actually named in the second call is still applied';

done_testing;
