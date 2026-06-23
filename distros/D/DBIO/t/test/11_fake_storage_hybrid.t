use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::SQLMaker;

# A fake driver storage class with a custom SQLMaker and a quoting default,
# standing in for e.g. DBIO::Oracle::Storage. Defined inline; pre-populate
# %INC so _build_fake_storage_class's require() is a no-op (no file on disk).
{
  package My::Fake::SQLMaker;
  use base 'DBIO::SQLMaker';
  sub _is_fake_maker { 1 }

  package My::Fake::Storage;
  use base 'DBIO::Storage::DBI';
  __PACKAGE__->sql_maker_class('My::Fake::SQLMaker');
  __PACKAGE__->sql_quote_char('"');
  __PACKAGE__->sql_name_sep('.');
}
$INC{'My/Fake/SQLMaker.pm'} = __FILE__;
$INC{'My/Fake/Storage.pm'}  = __FILE__;

# --- Gap 1: the hybrid pins the driver's sql_maker_class ---------------------
my $hybrid = DBIO::Test->_build_fake_storage_class('My::Fake::Storage');
ok $hybrid->isa('DBIO::Test::Storage'), 'hybrid ISA DBIO::Test::Storage';
ok $hybrid->isa('My::Fake::Storage'),   'hybrid ISA the driver storage';
is $hybrid->sql_maker_class, 'My::Fake::SQLMaker',
  'hybrid pins driver sql_maker_class, not the inherited default (gap 1)';
is $hybrid->sql_quote_char, '"', 'hybrid copies driver sql_quote_char';

# --- driver default quoting is honoured by init_schema -----------------------
{
  my $storage = DBIO::Test->init_schema(
    storage_type => 'My::Fake::Storage', no_deploy => 1,
  )->storage;
  isa_ok $storage->sql_maker, 'My::Fake::SQLMaker',
    'storage builds the driver SQLMaker offline';
  is $storage->{_sql_maker_opts}{quote_char}, '"',
    'driver default quote_char propagated to sql_maker_opts';
}

# --- Gap 2: init_schema(quote_char => '') overrides the driver default -------
# Empty string means "no quoting" and must win over the inherited '"'.
{
  my $storage = DBIO::Test->init_schema(
    storage_type => 'My::Fake::Storage', quote_char => '', no_deploy => 1,
  )->storage;
  is $storage->{_sql_maker_opts}{quote_char}, '',
    "empty-string quote_char arg wins over driver default (gap 2)";
  is $storage->sql_quote_char, '', 'override also set on the storage instance';
}

# --- explicit non-empty override --------------------------------------------
{
  my $storage = DBIO::Test->init_schema(
    storage_type => 'My::Fake::Storage', quote_char => '`',
    name_sep => '::', no_deploy => 1,
  )->storage;
  is $storage->{_sql_maker_opts}{quote_char}, '`', 'explicit quote_char arg wins';
  is $storage->{_sql_maker_opts}{name_sep}, '::', 'explicit name_sep arg wins';
}

done_testing;
