# ABSTRACT: a driver declares the foreign DBDs it takes as its access path
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;

# OFFLINE (karr k321, ADR 0059 addendum 2026-10-10). The DBD check of a
# declared storage asks the registry which driver a DBD belongs to. A driver
# whose transport IS the DBD of another driver (a ClickHouse driver over
# DBD::mysql) does not inherit that driver's storage, so the check would
# report its own transport as a foreign driver's. The driver says so with
# register_access_path_dbd; the declaration is per class, inherited by
# subclasses, and does not reach siblings.
#
# Pinned here:
#   1. a declared foreign DBD is no finding -- no warning, no throw under
#      driver_strict;
#   2. an undeclared foreign DBD is judged as before: warning, error under
#      driver_strict;
#   3. the declaration is inherited down, and does not leak to a sibling
#      class or up to the parent.

{
  package T::K321::DBH;
  sub new { my ($class, $dbd) = @_; bless { Driver => { Name => $dbd } }, $class }
  sub FETCH { $_[0]{$_[1]} }
  sub ping { 1 }
  sub disconnect { 1 }
}

# The driver whose DBDs the transport is.
{
  package T::K321::Foreign::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K321Foreign => __PACKAGE__);
  DBIO::Storage::DBI->register_driver(K321Other   => __PACKAGE__);
}

# The declaring driver: own DBD registered, foreign DBD declared. It does not
# inherit the foreign storage.
{
  package T::K321::Drv::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K321Own => __PACKAGE__);
  __PACKAGE__->register_access_path_dbd('K321Foreign');
}

{
  package T::K321::Drv::Storage::Sub;
  use base 'T::K321::Drv::Storage';
  use mro 'c3';
}

# A sibling driver: registered, declares nothing.
{
  package T::K321::Sibling::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K321Sibling => __PACKAGE__);
}

{
  package T::K321::SchemaBase;
  use base 'DBIO::Schema';
  our @KEEP;
  sub connect {
    my $schema = shift->SUPER::connect(@_);
    push @KEEP, $schema;
    return $schema;
  }
}

no warnings 'redefine';
local *DBI::connect = sub {
  my ($dbd) = $_[1] =~ /^dbi:(\w*)/i;
  return T::K321::DBH->new($dbd);
};
use warnings 'redefine';

my $n = 0;
sub storage_for {
  my ($storage_class, $dsn, $strict) = @_;
  my $class = 'T::K321::Schema' . ++$n;
  { no strict 'refs'; @{"${class}::ISA"} = ('T::K321::SchemaBase') }
  $class->storage_type("+$storage_class");
  my $schema = $class->connect($dsn);
  $schema->driver_strict(1) if $strict;
  return $schema->storage;
}

sub warnings_of (&) {
  my $code = shift;
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  $code->();
  return @w;
}

# 1. declared: quiet, also strict
for my $strict (0, 1) {
  my $storage = storage_for('T::K321::Drv::Storage', 'dbi:K321Foreign:x', $strict);
  my @w;
  lives_ok { @w = warnings_of { $storage->_determine_driver } }
    "a declared foreign DBD does not throw (strict=$strict)";
  is_deeply \@w, [], '... and does not warn';
  is ref($storage), 'T::K321::Drv::Storage', '... the storage stays the declared class';
}

# 2. undeclared foreign DBD: as before
{
  my $storage = storage_for('T::K321::Drv::Storage', 'dbi:K321Other:x');
  my @w = warnings_of { $storage->_determine_driver };
  is scalar(@w), 1, 'an undeclared foreign DBD still warns';
  like $w[0], qr/DBD::K321Other.*T::K321::Foreign::Storage/, '... naming DBD and class';

  $storage = storage_for('T::K321::Drv::Storage', 'dbi:K321Other:x', 1);
  throws_ok { $storage->_determine_driver } qr/Driver mismatch.*DBD::K321Other/s,
    '... and is refused under driver_strict';
}

# 3. inheritance and isolation
{
  my $storage = storage_for('T::K321::Drv::Storage::Sub', 'dbi:K321Foreign:x', 1);
  lives_ok { $storage->_determine_driver }
    'a subclass of the declaring class takes the declared DBD';

  $storage = storage_for('T::K321::Sibling::Storage', 'dbi:K321Foreign:x', 1);
  throws_ok { $storage->_determine_driver } qr/Driver mismatch.*DBD::K321Foreign/s,
    'the declaration does not reach a sibling class';

  ok(T::K321::Drv::Storage->_access_path_dbd_declared('K321Foreign'), 'the declaring class answers');
  ok(T::K321::Drv::Storage::Sub->_access_path_dbd_declared('K321Foreign'), 'a subclass answers');
  ok(!T::K321::Sibling::Storage->_access_path_dbd_declared('K321Foreign'), 'a sibling does not');
  ok(!DBIO::Storage::DBI->_access_path_dbd_declared('K321Foreign'), 'nor does the base');
  ok(!T::K321::Drv::Storage->_access_path_dbd_declared('K321Other'), 'only the declared names');
}

done_testing;
