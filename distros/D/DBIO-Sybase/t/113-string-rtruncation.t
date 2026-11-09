use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::Core;
use DBIO::Schema;

# karr k97, maintainer's decision: ASE cuts a string that is too long to the
# width of the column without a word (a char(10) takes 11 characters,
# varchar(5) turns 'abcdefgh' into 'abcde'). `set string_rtruncation on` makes
# that Msg 9502 ("string data right truncated"). The storage sets it on every
# connection it makes: the first connect, a reconnect, and the storage that
# writes (the writer storage of the ASE class). Silent cutting is never wanted.
# Nothing here connects: DBI->connect is replaced by a handle that records the
# statements it is given.

my @SQL;
{
  package T::K97::DBH;
  sub new {
    bless { Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
            Driver => { Name => 'Sybase' }, syb_oc_version => $_[1],
            syb_dynamic_supported => 1 }, $_[0];
  }
  sub FETCH      { $_[0]{$_[1]} }
  sub ping       { 1 }
  sub disconnect { $_[0]{Active} = 0; 1 }
  sub begin_work { 1 } sub commit { 1 } sub rollback { 1 }
  sub err { undef } sub errstr { undef }
  sub do { my ($self, $sql) = @_; push @SQL, [ $self, $sql ]; 1 }
  sub selectrow_arrayref { [ 1, 'DBMS_NAME', 'SQL Server' ] }
  sub selectrow_array    { 1 }
  sub quote { "'$_[1]'" }
}
{
  package T::K97::Result::T;
  use base 'DBIO::Core';
  __PACKAGE__->table('t');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  package T::K97::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(T => 'T::K97::Result::T');
}

$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

my $OC;
no warnings 'redefine';
local *DBI::connect = sub { T::K97::DBH->new($OC) };
use warnings 'redefine';

sub rtrunc { scalar grep { $_->[1] =~ /\Aset string_rtruncation on\z/i } @SQL }

for my $flavour ([ FreeTDS => 'freetds v1.3.17' ], [ 'Open Client' => 'Sybase Open Client 15.7' ]) {
  my ($label, $version) = @$flavour;
  $OC = $version;
  @SQL = ();
  my $schema  = T::K97::Schema->connect('dbi:Sybase:server=x', 'u', 'p');
  my $storage = $schema->storage;
  $storage->dbh;
  is rtrunc(), 1, "$label: the first connection sets string_rtruncation on";

  my $first = $SQL[0][0];
  $storage->disconnect;
  $storage->dbh;
  is rtrunc(), 2, "$label: ... and so does the reconnect";

  my $writer = $storage->_writer_storage;
  @SQL = ();
  $writer->dbh;
  is rtrunc(), 1, "$label: ... and the writer storage's own connection";
  $schema->storage->disconnect;
}

done_testing;
