use strict;
use warnings;

package DBIx::Migration;

our $VERSION = '0.12';

use subs 'dbh';

use Class::Tiny qw( debug dbh dir dsn password username );

use DBI                   qw();
use File::Slurp           qw();
use File::Spec::Functions qw();
use Try::Tiny             qw();

sub dbh {
  my $self = shift;

  if ( @_ ) {
    $self->{ dbh } = $_[ 0 ];
  }
  unless ( defined $self->{ dbh } ) {
    $self->{ dbh } = $self->_build_dbh;
  }

  return $self->{ dbh };
}

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

sub migrate {
  my ( $self, $wanted ) = @_;

  $wanted = $self->_latest unless defined $wanted;

  my $fatal_error;
  my $return_value = Try::Tiny::try {
    my $version = $self->version;

    # enable transaction turning AutoCommit off
    $self->{ _dbh } = $self->dbh->clone( {} );
    $self->{ _dbh }->begin_work;

    $self->_create_migration_table, $version = 0 unless defined $version;

    my @need;
    my $type;
    if ( $wanted == $version ) {
      print qq/Database is already at version $wanted\n/ if $self->debug;
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
        print qq/Processing "$name"\n/ if $self->debug;
        my $text      = File::Slurp::read_file( $name );
        my $delimiter = ( $text =~ m/\A-- *dbix_migration_delimiter: *([[:graph:]])/ ) ? $1 : ';';
        print qq/Delimiter is $delimiter\n/ if $self->debug;
        $text =~ s/\s*--.*$//mg;
        for my $sql ( split /$delimiter/, $text ) {
          $sql =~ s/\A\s*//;
          next unless $sql =~ /\w/;
          print qq/$sql\n/ if $self->debug;
          # prepend $sql to error message
          local $self->{ _dbh }->{ HandleError } = sub { $_[ 0 ] = "$sql\n$_[0]"; return 0; };
          $self->{ _dbh }->do( $sql );
        }
        $ver -= 1 if ( ( $ver > 0 ) && ( $type eq 'down' ) );
        $self->_update_migration_table( $ver );
      }
      return 1;
    } else {
      my $newver = $self->version;
      print qq/Database is at version $newver, couldn't migrate to version $wanted\n/
        if ( $self->debug && ( $wanted != $newver ) );
      return 0;
    }
  }
  Try::Tiny::catch {
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
    my $sth = $dbh->prepare( <<'EOF');
SELECT value FROM dbix_migration WHERE name = ?;
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
      $file = File::Spec::Functions::catfile( $self->dir, $file );
      print qq/Found "$file"\n/ if $self->debug;
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

sub _create_migration_table {
  my $self = shift;

  $self->{ _dbh }->do( <<'EOF');
CREATE TABLE dbix_migration ( name VARCHAR(64) PRIMARY KEY, value VARCHAR(64) );
EOF
  $self->{ _dbh }->do( <<'EOF', undef, 'version', 0 );
INSERT INTO dbix_migration ( name, value ) VALUES ( ?, ? );
EOF
}

sub _update_migration_table {
  my ( $self, $version ) = @_;

  $self->{ _dbh }->do( <<'EOF', undef, $version, 'version' );
UPDATE dbix_migration SET value = ? WHERE name = ?;
EOF
}

1;
