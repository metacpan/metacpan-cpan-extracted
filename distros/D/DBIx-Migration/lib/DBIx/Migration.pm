package DBIx::Migration;

our $VERSION = '0.15';

use Moo;
use MooX::SetOnce;
use MooX::StrictConstructor;

use DBI                     ();
use DBI::Const::GetInfoType qw( %GetInfoType );
use File::Slurp             qw( read_file );
use File::Spec::Functions   qw( catfile );
use Log::Any                qw( $Logger );
use Try::Tiny               qw( catch try );

use namespace::clean -except => [ qw( before new ) ];

has [ qw( dbh dsn tracking_schema ) ] => ( is => 'lazy' );
has tracking_table                    => ( is => 'lazy', init_arg => undef );
has dir                               => ( is => 'rw',   once     => 1 );
has [ qw( password username ) ]       => ( is => 'ro' );

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

sub _build_tracking_schema {
  my $self = shift;

  if ( my ( undef, $driver ) = DBI->parse_dsn( $self->dsn ) ) {
    return 'public' if $driver eq 'Pg';
  }
  return;
}

sub _build_tracking_table {
  my $self = shift;

  my $tracking_schema = $self->tracking_schema;
  return ( defined $tracking_schema ? "$tracking_schema." : '' ) . 'dbix_migration';
}

sub BUILD {
  my ( $self, $args ) = @_;

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
}

sub migrate {
  my ( $self, $wanted ) = @_;

  $wanted = $self->_latest unless defined $wanted;

  my $fatal_error;
  my $return_value = try {
    my $version = $self->version;

    # enable transaction turning AutoCommit off
    $self->{ _dbh } = $self->dbh->clone( {} );
    $self->{ _dbh }->begin_work;

    $self->_create_tracking_table, $version = 0 unless defined $version;

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
        my $text      = read_file( $name );
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
    $self->{ _dbh }->rollback;
    # rethrow exception
    die $fatal_error;
  }
  # commit transaction turning AutoCommit on again
  $self->{ _dbh }->commit;
  return $return_value;
}

sub version {
  my $self = shift;

  my $dbh = $self->dbh;
  eval {
    my $tracking_table = $self->tracking_table;
    $Logger->debugf( "Reading tracking table '%s'", $tracking_table );
    my $sth = $dbh->prepare( <<"EOF");
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
    opendir( my $dh, $self->dir )
      or die sprintf( qq/Cannot open directory '%s': %s/, $self->dir, $! );
    while ( my $file = readdir( $dh ) ) {
      next unless $file =~ /\D*${i}_$type\.sql\z/;
      $file = catfile( $self->dir, $file );
      $Logger->debugf( "Found migration '%s'", $file );
      push @files, { name => $file, version => $i };
    }
    closedir( $dh );
  }

  return ( @files and @$need == @files ) ? \@files : undef;
}

sub _latest {
  my $self = shift;

  opendir( my $dh, $self->dir )
    or die sprintf( qq/Cannot open directory '%s': %s/, $self->dir, $! );
  my $latest = 0;
  while ( my $file = readdir( $dh ) ) {
    next unless $file =~ /_up\.sql\z/;
    $file =~ /\D*(\d+)_up.sql\z/;
    $latest = $1 if $1 > $latest;
  }
  closedir( $dh );

  return $latest;
}

sub _create_tracking_table {
  my $self = shift;

  my $tracking_table = $self->tracking_table;
  $Logger->debugf( "Creating tracking table '%s'", $tracking_table );
  $self->{ _dbh }->do( <<"EOF");
CREATE TABLE $tracking_table ( name VARCHAR(64) PRIMARY KEY, value VARCHAR(64) );
EOF
  $self->{ _dbh }->do( <<"EOF", undef, 'version', 0 );
INSERT INTO $tracking_table ( name, value ) VALUES ( ?, ? );
EOF
}

sub _update_tracking_table {
  my ( $self, $version ) = @_;

  my $tracking_table = $self->tracking_table;
  $Logger->debugf( "Updating tracking table '%s'", $tracking_table );
  $self->{ _dbh }->do( <<"EOF", undef, $version, 'version' );
UPDATE $tracking_table SET value = ? WHERE name = ?;
EOF
}

1;
