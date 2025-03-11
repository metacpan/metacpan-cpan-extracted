package DBIx::Migration;

our $VERSION = '0.20';

use Moo;
use MooX::SetOnce;
use MooX::StrictConstructor;

use DBI                     ();
use DBI::Const::GetInfoType qw( %GetInfoType );
use Log::Any                qw( $Logger );
use Try::Tiny               qw( catch try );
use Types::Path::Tiny       qw( Dir );

use namespace::clean -except => [ qw( before new ) ];

has [ qw( dbh dsn ) ]           => ( is => 'lazy' );
has dir                         => ( is => 'rw', once => 1, isa => Dir, coerce => 1 );
has [ qw( password username ) ] => ( is => 'ro' );
has tracking_table              => ( is => 'ro', default => 'dbix_migration' );

sub _build_dbh {
  my $self = shift;

  return DBI->connect(
    $self->dsn,
    $self->username,
    $self->password,
    {
      RaiseError => 1,
      PrintError => 0,
      AutoCommit => 1    # see below "begin_work" based transaction handling
    }
  );
}

sub _build_dsn {
  my $self = shift;

  return $self->dbh->get_info( $GetInfoType{ SQL_DATA_SOURCE_NAME } );
}

sub BUILD {
  my ( $self, $args ) = @_;

  # new() is overloaded: check consistency of attributes
  if ( exists $args->{ dsn } ) {
    die 'dsn and dbh cannot be used at the same time'
      if exists $args->{ dbh };
  } elsif ( exists $args->{ dbh } ) {
    foreach ( qw( dsn username password ) ) {
      die "dbh and $_ cannot be used at the same time"
        if exists $args->{ $_ };
    }
  } else {
    die 'both dsn and dbh are not set';
  }

  # driver should match subclass
  my $class = ref $self;
  if ( ( my @package = split( /::/, $class ) ) > 2 ) {
    my $driver = $self->driver;
    die "subclass $class cannot handle $driver driver"
      unless $driver eq $package[ -1 ];
  }
}

# overrideable
sub apply_managed_schema { }

# overrideable
sub quoted_tracking_table {
  my $self = shift;

  return $self->dbh->quote_identifier( $self->tracking_table );
}

# can be used as an object method ($dsn not specified) and as a class method
# ($dsn specified)
sub driver {
  my ( $self, $dsn ) = @_;

  return ( DBI->parse_dsn( defined $dsn ? $dsn : $self->dsn ) )[ 1 ];
}

sub migrate {
  my ( $self, $wanted ) = @_;
  Dir->assert_valid( $self->dir );

  $wanted = $self->_latest unless defined $wanted;

  my $fatal_error;
  my $return_value = try {
    my $version = $self->version;

    $self->{ _dbh } = $self->dbh->clone(
      {
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
      }
    );
    # enable transaction turning AutoCommit off
    $self->{ _dbh }->begin_work;

    $self->_create_tracking_table, $version = 0 unless defined $version;

    $self->apply_managed_schema;

    my @need;
    my $type;
    if ( $wanted == $version ) {
      $Logger->debugf( 'Database is already at migration version %d', $wanted );
      return 1;
    } elsif ( $wanted > $version ) {    # upgrade
      $type = 'up';
      $version += 1;
      @need = $version .. $wanted;
    } else {                            # downgrade
      $type = 'down';
      $wanted += 1;
      @need = reverse( $wanted .. $version );
    }
    my $files = $self->_files( $type, \@need );
    if ( defined $files ) {
      for my $file ( @$files ) {
        my $name = $file->{ name };
        my $ver  = $file->{ version };
        $Logger->debugf( "Processing migration '%s'", $name );
        my $text      = $name->slurp_raw;
        my $delimiter = ( $text =~ m/\A-- *dbix_migration_delimiter: *([[:graph:]])/ ) ? $1 : ';';
        $Logger->debugf( "Migration section delimiter is '%s'", $delimiter );
        $text =~ s/\s*--.*$//mg;
        for my $sql ( split /$delimiter/, $text ) {
          $sql =~ s/\A\s*//;
          next unless $sql =~ /\w/;
          # prepend $sql to error message
          local $self->{ _dbh }->{ HandleError } = sub { $_[ 0 ] = "$sql\n$_[0]"; return 0; };
          $self->{ _dbh }->do( $sql );
        }
        $ver -= 1 if ( ( $ver > 0 ) && ( $type eq 'down' ) );
        $self->_update_tracking_table( $ver );
      }
      return 1;
    } else {
      my $newver = $self->version;
      $Logger->debugf( "Database is at version %d, couldn't migrate to version %d", $newver, $wanted )
        if $wanted != $newver;
      return 0;
    }
  } catch {
    $fatal_error = $_;
  };

  if ( $fatal_error ) {
    # rollback transaction turning AutoCommit on again
    $self->{ _dbh }->rollback if exists $self->{ _dbh };
    delete $self->{ _dbh };
    # rethrow exception
    die $fatal_error;
  }
  # commit transaction turning AutoCommit on again
  $self->{ _dbh }->commit;
  delete $self->{ _dbh };

  return $return_value;
}

sub version {
  my $self = shift;

  my $dbh = $self->dbh;
  local @{ $dbh }{ qw( RaiseError PrintError ) } = ( 1, 0 );
  try {
    my $tracking_table = $self->quoted_tracking_table;
    $Logger->debugf( "Reading tracking table '%s'", $tracking_table );
    my $sth = $dbh->prepare( <<"EOF" );
SELECT value FROM $tracking_table WHERE name = ?;
EOF
    $sth->execute( 'version' );
    my $version = undef;
    for my $val ( $sth->fetchrow_arrayref ) {
      $version = $val->[ 0 ];
    }
    $version;
  };
}

sub _files {
  my ( $self, $type, $need ) = @_;

  my @files;
  for my $i ( @$need ) {
    no warnings 'uninitialized';
    $self->dir->visit(
      sub {
        return unless m/\D*${i}_$type\.sql\z/;
        $Logger->debugf( "Found migration '%s'", $_ );
        push @files, { name => $_, version => $i };
      }
    );
  }

  return ( @files and @$need == @files ) ? \@files : undef;
}

sub _latest {
  my $self = shift;

  my $latest = 0;
  $self->dir->visit(
    sub {
      return unless m/_up\.sql\z/;
      m/\D*(\d+)_up\.sql\z/;
      $latest = $1 if $1 > $latest;
    }
  );

  return $latest;
}

sub _create_tracking_table {
  my $self = shift;

  my $tracking_table = $self->quoted_tracking_table;
  $Logger->debugf( "Creating tracking table '%s'", $tracking_table );
  $self->{ _dbh }->do( <<"EOF" );
CREATE TABLE $tracking_table ( name VARCHAR(64) PRIMARY KEY, value VARCHAR(64) );
EOF
  $self->{ _dbh }->do( <<"EOF", undef, 'version', 0 );
INSERT INTO $tracking_table ( name, value ) VALUES ( ?, ? );
EOF
}

sub _update_tracking_table {
  my ( $self, $version ) = @_;

  my $tracking_table = $self->quoted_tracking_table;
  $Logger->debugf( "Updating tracking table '%s'", $tracking_table );
  $self->{ _dbh }->do( <<"EOF", undef, $version, 'version' );
UPDATE $tracking_table SET value = ? WHERE name = ?;
EOF
}

1;
