package SybaseFakeDBH;
# A DBI->connect that connects to nothing, and the handle it returns: what the
# Sybase storage asks a client library and a server (syb_oc_version,
# syb_dynamic_supported, the placeholder probes, sp_server_info,
# syb_server_version_string). Shared by the offline tests that need to see which
# class a storage becomes and how often it logs in; t/59 keeps its own copy.

use strict;
use warnings;

our $OPEN_CLIENT = 'Sybase Client-Library/16.0/P/x86_64/Linux';
our $FREETDS     = 'freetds v1.3.17';

# What the fake client library and the fake server answer; set per case.
our $OC_VERSION   = $OPEN_CLIENT;
our $DYNAMIC      = 1;       # syb_dynamic_supported
our $PLACEHOLDERS = 1;       # select ?
our $TYPELESS     = 1;       # select 1 where 1 = ?
our $PRODUCT      = 'ase';   # or 'mssql': the answer of sp_server_info
our $SERVER_VERSION = 'Adaptive Server Enterprise/16.0 SP02';   # syb_server_version_string

our (@CONNECTS, @ASKED, @DONE);

sub reset_records { @CONNECTS = @ASKED = @DONE = () }

sub install {
  require DBI;
  no warnings 'redefine';
  *DBI::connect = sub {
    shift;
    push @CONNECTS, [ @_ ];
    my ($dbd) = $_[0] =~ /^dbi:(\w*)/i;
    return SybaseFakeDBH::DBH->new($dbd);
  };
}

{
  package SybaseFakeDBH::DBH;

  sub new {
    my ($class, $dbd) = @_;
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
      Driver => { Name => $dbd },
      ( $dbd eq 'Sybase' ? (
        syb_oc_version            => $SybaseFakeDBH::OC_VERSION,
        syb_dynamic_supported     => $SybaseFakeDBH::DYNAMIC,
        syb_server_version_string => $SybaseFakeDBH::SERVER_VERSION,
      ) : () ),
    }, $class;
  }

  sub FETCH      { $_[0]{$_[1]} }
  sub STORE      { $_[0]{$_[1]} = $_[2] }
  sub ping       { 1 }
  sub disconnect { $_[0]{Active} = 0; 1 }

  # The placeholder probes of DBIO::Storage::DBI are a do() with a bind value.
  sub do {
    my ($self, $sql) = @_;
    push @SybaseFakeDBH::DONE, $sql;
    die "this connection binds no value without a type\n"
      if $sql =~ /where 1 = \?/ and not $SybaseFakeDBH::TYPELESS;
    die "this connection takes no placeholders\n"
      if $sql =~ /\?/ and not $SybaseFakeDBH::PLACEHOLDERS;
    return 1;
  }

  # sp_server_info @attribute_id=1: recorded, so a case can show that the server is never asked what it is.
  sub selectrow_arrayref {
    my ($self, $sql) = @_;
    push @SybaseFakeDBH::ASKED, $sql;
    return [ 1, 'DBMS_NAME',
      $SybaseFakeDBH::PRODUCT eq 'mssql' ? 'Microsoft SQL Server' : 'SQL Server' ];
  }
}

1;
