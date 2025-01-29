package DBIx::Migration;

use strict;
use warnings;
use parent qw( Class::Accessor::Fast );

use DBI;
use File::Slurp;
use File::Spec;

our $VERSION = '0.09';

__PACKAGE__->mk_accessors( qw( debug dir dsn password username dbh  ) );

sub migrate {
  my ( $self, $wanted ) = @_;
  $self->_connect;
  $wanted = $self->_newest unless defined $wanted;
  my $version = $self->_version;
  if ( defined $version && ( $wanted == $version ) ) {
    print "Database is already at version $wanted\n" if $self->debug;
    return 1;
  }

  unless ( defined $version ) {
    $self->_create_migration_table;
    $version = 0;
  }

  # Up- or downgrade
  my @need;
  my $type = 'down';
  if ( $wanted > $version ) {
    $type = 'up';
    $version += 1;
    @need = $version .. $wanted;
  } else {
    $wanted += 1;
    @need = reverse( $wanted .. $version );
  }
  my $files = $self->_files( $type, \@need );
  if ( defined $files ) {
    for my $file ( @$files ) {
      my $name = $file->{ name };
      my $ver  = $file->{ version };
      print qq/Processing "$name"\n/ if $self->debug;
      next unless $file;
      my $text = read_file( $name );
      $text =~ s/\s*--.*$//g;
      for my $sql ( split /;/, $text ) {
        next unless $sql =~ /\w/;
        print "$sql\n" if $self->debug;
        $self->{ _dbh }->do( $sql );
        if ( $self->{ _dbh }->err ) {
          die "Database error: " . $self->{ _dbh }->errstr;
        }
      }
      $ver -= 1 if ( ( $ver > 0 ) && ( $type eq 'down' ) );
      $self->_update_migration_table( $ver );
    }
  } else {
    my $newver = $self->_version;
    print "Database is at version $newver, couldn't migrate to $wanted\n"
      if ( $self->debug && ( $wanted != $newver ) );
    return 0;
  }
  $self->_disconnect;
  return 1;
}

sub version {
  my $self = shift;
  $self->_connect;
  my $version = $self->_version;
  $self->_disconnect;
  return $version;
}

sub _connect {
  my $self = shift;
  return $self->{ _dbh } = $self->dbh->clone( {} ) if $self->dbh;
  $self->{ _dbh } = DBI->connect(
    $self->dsn,
    $self->username,
    $self->password,
    {
      RaiseError => 0,
      PrintError => 0,
      AutoCommit => 1
    }
  ) or die sprintf( qq/Couldn't connect to database %s: %s/, $self->dsn, $DBI::errstr );
  $self->dbh( $self->{ _dbh } );
}

sub _create_migration_table {
  my $self = shift;
  $self->{ _dbh }->do( <<"EOF");
CREATE TABLE dbix_migration (
    name VARCHAR(64) PRIMARY KEY,
    value VARCHAR(64)
);
EOF
  $self->{ _dbh }->do( <<"EOF");
    INSERT INTO dbix_migration ( name, value ) VALUES ( 'version', '0' );
EOF
}

sub _disconnect {
  my $self = shift;
  $self->{ _dbh }->disconnect;
}

sub _files {
  my ( $self, $type, $need ) = @_;
  my @files;
  for my $i ( @$need ) {
    opendir( DIR, $self->dir ) or die $!;
    while ( my $file = readdir( DIR ) ) {
      next unless $file =~ /(^|\D)${i}_$type\.sql$/;
      $file = File::Spec->catdir( $self->dir, $file );
      push @files, { name => $file, version => $i };
    }
    closedir( DIR );
  }
  return undef unless @$need == @files;
  return @files ? \@files : undef;
}

sub _newest {
  my $self   = shift;
  my $newest = 0;

  opendir( DIR, $self->dir ) or die $!;
  while ( my $file = readdir( DIR ) ) {
    next unless $file =~ /_up\.sql$/;
    $file =~ /\D*(\d+)_up.sql$/;
    $newest = $1 if $1 > $newest;
  }
  closedir( DIR );

  return $newest;
}

sub _update_migration_table {
  my ( $self, $version ) = @_;
  $self->{ _dbh }->do( <<"EOF");
UPDATE dbix_migration SET value = '$version' WHERE name = 'version';
EOF
}

sub _version {
  my $self    = shift;
  my $version = undef;
  eval {
    my $sth = $self->{ _dbh }->prepare( <<"EOF");
SELECT value FROM dbix_migration WHERE name = ?;
EOF
    $sth->execute( 'version' );
    for my $val ( $sth->fetchrow_arrayref ) {
      $version = $val->[ 0 ];
    }
  };
  return $version;
}

1;
