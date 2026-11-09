# ABSTRACT: a schema always has a driver -- a schema that declares none is refused before any storage is built
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI ();
use DBIO;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Test::Storage;

# OFFLINE (karr k308, ADR 0067). A schema whose storage class resolves to the
# generic DBIO::Storage::DBI declares no driver, and DBIO::Schema::connection
# refuses it before it builds a storage -- for every schema class, with or
# without sources, made by use DBIO 'Schema' or by use base. There is no
# warning mode and no guess from the DSN, even when a driver is registered for
# the DBD it names.
#
# What this file claims:
#   1. a schema without a declared driver is refused at connect and at
#      connection, with any connect info and with none: no storage is built,
#      nothing connects, and the message names the schema class and the ways
#      to declare a driver;
#   2. so is one whose storage_type names the generic class itself;
#   3. a declaration is any other storage class -- by a shortcut, by a driver
#      component's connection(), or by storage_type set on the class or on a
#      clone before connecting; the clone's does not reach the class.
#
# THE SUBSTITUTIONS: a fake driver DBIO::K308Drv, its storage defined here and
# registered for a DBD name no DBD carries; DBI->connect records that it was
# asked and returns nothing.

my @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { push @CONNECTS, $_[1]; return undef };
}

{
  package DBIO::K308Drv::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K308Drv => __PACKAGE__);
  $INC{'DBIO/K308Drv/Storage.pm'} = __FILE__;
  our $BUILT = 0;
  sub new { $BUILT++; shift->next::method(@_) }
}

# A driver component, as a driver dist ships one: it pins its storage class in
# connection() and passes on.
{
  package DBIO::K308Drv;
  use base 'DBIO::Base';
  $INC{'DBIO/K308Drv.pm'} = __FILE__;
  sub connection {
    my $self = shift;
    $self->storage_type('+DBIO::K308Drv::Storage');
    return $self->next::method(@_);
  }
}

# The shortcut stub of the fake driver.
BEGIN {
  package DBIO::Shortcut::k308drv;
  sub apply { DBIO->apply_driver($_[1], 'K308Drv') }
  $INC{'DBIO/Shortcut/k308drv.pm'} = __FILE__;
}

{ package T::K308::Result; use base 'DBIO::Core'; __PACKAGE__->table('k308'); __PACKAGE__->add_columns('id'); }

# --- schema classes -----------------------------------------------------------

{ package T::K308::BaseNoSources; use base 'DBIO::Schema'; }
{
  package T::K308::BaseSources;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Thing => 'T::K308::Result');
}
{ package T::K308::PragmaNoDriver; use DBIO 'Schema'; }
{
  package T::K308::ExplicitGeneric;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::Storage::DBI');
}
{ package T::K308::Shortcut; use DBIO 'Schema', -k308drv; }
{
  package T::K308::Component;
  use DBIO 'Schema';
  __PACKAGE__->load_components('+DBIO::K308Drv');
}
{
  package T::K308::StorageType;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::K308Drv::Storage');
}
{ package T::K308::ForClone; use base 'DBIO::Schema'; }

my $DSN = 'dbi:K308Drv:db=t';

# --- 1 + 2. refused -----------------------------------------------------------
for my $class (qw(
  T::K308::BaseNoSources T::K308::BaseSources T::K308::PragmaNoDriver
  T::K308::ExplicitGeneric
)) {
  for my $form (
    [ 'a DSN whose DBD has a registered driver' => [ $DSN, 'u', 'p' ] ],
    [ 'a connection coderef'                   => [ sub { die "never called\n" } ] ],
    [ 'no connect info'                        => [] ],
  ) {
    my ($how, $info) = @$form;
    my $what = "$class, $how";

    @CONNECTS = ();
    local $DBIO::K308Drv::Storage::BUILT = 0;

    throws_ok { $class->connect(@$info) } qr/Schema class \Q$class\E declares no driver/,
      "$what: connect is refused, naming the schema class";
    isa_ok $@, 'DBIO::Exception', "$what: what is thrown";
    like "$@", qr/ADR 0067/, "$what: ... naming the decision";
    like "$@", qr/use DBIO 'Schema', -<driver>/, "$what: ... the shortcut as a way to declare";
    like "$@", qr/component/, "$what: ... the driver component as another";
    like "$@", qr/storage_type/, "$what: ... and storage_type";
    is scalar(@CONNECTS), 0, "$what: nothing connects";
    is $DBIO::K308Drv::Storage::BUILT, 0, "$what: the registered driver is not guessed";

    throws_ok { $class->connection(@$info) } qr/declares no driver/,
      "$what: connection on the class is refused too";
    ok !defined $class->storage, "$what: ... and leaves the class without a storage";
  }
}

# --- 3. declared --------------------------------------------------------------
for my $class (qw( T::K308::Shortcut T::K308::Component T::K308::StorageType )) {
  @CONNECTS = ();
  my $schema;
  lives_ok { $schema = $class->connect($DSN, 'u', 'p') } "$class: connects";
  isa_ok $schema->storage, 'DBIO::K308Drv::Storage', "$class: the storage";
  is scalar(@CONNECTS), 0, "$class: ... lazily, nothing connected yet";
}

{
  my $clone = T::K308::ForClone->clone;
  $clone->storage_type('+DBIO::Test::Storage');
  my $schema;
  lives_ok { $schema = $clone->connect(sub { }) }
    'a storage_type set on a clone before connecting is a declaration';
  isa_ok $schema->storage, 'DBIO::Test::Storage', '... the storage';
  throws_ok { T::K308::ForClone->connect(sub { }) } qr/declares no driver/,
    '... which stays with the clone: the class still declares none';
}

done_testing;
