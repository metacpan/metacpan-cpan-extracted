use strict;
use warnings;
use Test::More;

# Offline regression for karr k45: DBIO::Sybase::Storage::ASE wraps every
# method in @also_proxy_to_extra_storages (cursor_class among them) so a call
# is fanned out to the _writer_storage/_bulk_storage. The wrapper called
# $self->_writer_storage unconditionally -- an instance accessor that dies on
# a class invocant. Core's connect_info (ADR 0050) resets cursor_class via
#   $self->cursor_class(ref($self)->cursor_class)
# i.e. as a CLASS method, so every live connect died inside ASE::_init with
# "Class::XSAccessor: invalid instance method invocant". t/22 never saw it
# because it runs _init without any connect_info set, so the nested
# connect_info call on the writer storage stays a getter.

use_ok 'DBIO::Sybase::Storage::ASE';

{ package K45::Cursor; our @ISA = ('DBIO::Storage::DBI::Cursor'); sub k45 { 1 } }

my $ase = 'DBIO::Sybase::Storage::ASE';

# The runtime FreeTDS trait is synthesised as "<class>::FreeTDS" on top of the
# ASE class (DBIO::Sybase::Storage::_init); the stack trace from the live run
# had exactly that class as invocant, so exercise it as well.
my $freetds = "${ase}::FreeTDS";
{
  no strict 'refs';
  @{"${freetds}::ISA"} = ($ase, 'DBIO::Sybase::Storage::FreeTDS');
}

for my $class ($ase, $freetds) {
  my $got = eval { $class->cursor_class };
  is $@, '', "$class->cursor_class as class method does not die";
  ok defined $got && length $got, "$class->cursor_class returns the class default";
}

# connect_info on an instance: the ADR 0050 reset path.
{
  my $obj = $ase->new;
  my $ok = eval { $obj->connect_info([ 'dbi:Sybase:host=nohost' ]); 1 };
  ok $ok, 'connect_info on an ASE instance survives the cursor_class reset'
    or diag $@;
}

# The full _init path with a real connect_info: builds the writer storage and
# calls connect_info on it. Only the server-bound parts are neutralised.
{
  my $obj = $ase->new;
  $obj->connect_info([ 'dbi:Sybase:host=nohost' ]);

  no warnings 'redefine';
  local *DBIO::Sybase::Storage::ASE::_using_freetds         = sub { 1 };
  local *DBIO::Sybase::Storage::ASE::_using_freetds_version = sub { 0 };
  local *DBIO::Sybase::Storage::ASE::_set_max_connect       = sub { };
  local *DBIO::Storage::DBI::_init                          = sub { };

  my $ok = eval { $obj->_init; 1 };
  ok $ok, '_init with connect_info set creates the writer storage without dying'
    or diag $@;
  ok defined $obj->_writer_storage, '_writer_storage was built';

  # The proxy must still fan instance calls out to the writer storage -- use a
  # class distinct from the default so an un-proxied writer would differ.
  $obj->cursor_class('K45::Cursor');
  is $obj->_writer_storage->cursor_class, 'K45::Cursor',
    'instance call of a proxied accessor still reaches the writer storage'
    if $obj->_writer_storage;
}

done_testing;
