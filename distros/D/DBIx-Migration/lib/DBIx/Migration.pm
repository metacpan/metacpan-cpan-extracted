package DBIx::Migration;

our $VERSION = '0.30';

use feature qw( state );

use Moo;
use MooX::SetOnce;
use MooX::StrictConstructor;

use DBI                     ();
use DBI::Const::GetInfoType qw( %GetInfoType );
use Log::Any                qw( $Logger );
use String::Expand          qw( expand_string );
use Try::Tiny               qw( catch try );
use Type::Params            qw( signature );
use Types::Common::Numeric  qw( PositiveInt PositiveOrZeroInt );
use Types::Path::Tiny       qw( Dir );
use Types::Self             qw( Self );
use Types::Standard         qw( ArrayRef HashRef Str );

use namespace::clean -except => [ qw( before new ) ];

# 1st alternative set of constructor attributes
has dsn => ( is => 'lazy', isa => Str );

sub _build_dsn {
  my $self = shift;

  return $self->dbh->get_info( $GetInfoType{ SQL_DATA_SOURCE_NAME } );
}
has [ qw( password username ) ] => ( is => 'ro', isa => Str );

# 2nd alternative set of constructor attributes
has dbh => ( is => 'lazy' );

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

my $MigrationsDir = Type::Tiny->new(
  name       => 'MigrationsDir',
  parent     => Dir,
  constraint => sub { __PACKAGE__->latest( $_ ) },
  coercion   => 1                                    # inherit from parent
);
has dir            => ( is => 'rw',   isa => $MigrationsDir, once => 1, coerce => 1 );
has do_before      => ( is => 'lazy', isa => ArrayRef [ Str | ArrayRef ], default => sub { [] } );
has do_while       => ( is => 'lazy', isa => ArrayRef [ Str | ArrayRef ], default => sub { [] } );
has tracking_table => ( is => 'ro',   isa => Str, default => 'dbix_migration' );
has placeholders   => ( is => 'lazy', isa => HashRef [ Str ], default => sub { {} }, init_arg => undef );

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
sub create_tracking_table {
  my $self = shift;

  my $tracking_table = $self->quoted_tracking_table;
  $Logger->debugf( "Create tracking table '%s'", $tracking_table );
  $self->dbh->do( "CREATE TABLE IF NOT EXISTS $tracking_table ( name VARCHAR(64) PRIMARY KEY, value VARCHAR(64) )" );
}

# can be used as an object method ($dsn not specified) and as a class method
# ($dsn specified)
sub driver {
  my ( $self, $dsn ) = @_;

  return ( DBI->parse_dsn( defined $dsn ? $dsn : $self->dsn ) )[ 1 ];
}

sub latest {
  # coercion is implicitly enabled because the Dir type constraint has a coercion
  state $signature = signature( method => 1, positional => [ Dir, { optional => 1 } ] );
  my ( $self, $dir ) = $signature->( @_ );
  $dir = $self->dir unless defined $dir;
  Dir->assert_valid( undef ) unless defined $dir;

  my $latest = 0;
  $dir->visit(
    sub {
      return unless m/\D*([1-9][0-9]*)_up\.sql\z/;
      $latest = $1 if $1 > $latest;
    }
  );

  return PositiveInt->assert_return( $latest );
}

sub migrate {
  state $signature = signature( method => Self, positional => [ PositiveOrZeroInt, { optional => 1 } ] );
  my ( $self, $target ) = $signature->( @_ );
  Dir->assert_valid( $self->dir );

  $target = $self->latest unless defined $target;

  $Logger->debugf( "Will use DBI DSN '%s'", $self->dsn );

  my $fatal_error;
  my $return_value = try {

    # on purpose outside of the transaction
    # doesn't use _dbh (the cloned dbh)
    $self->create_tracking_table;

    $self->{ _dbh } = $self->dbh->clone(
      {
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
      }
    );

    $Logger->debugf( "Execute 'before' transaction todo: '%s'", $_ ), $self->{ _dbh }->do( ref eq 'ARRAY' ? @$_ : $_ )
      foreach @{ $self->do_before };

    $Logger->debug( 'Enable transaction turning AutoCommit off' );
    $self->{ _dbh }->begin_work;

    $Logger->debugf( "Execute 'while' transaction todo: '%s'", $_ ), $self->{ _dbh }->do( ref eq 'ARRAY' ? @$_ : $_ )
      foreach @{ $self->do_while };

    my $version = $self->version;
    $self->_initialize_tracking_table, $version = 0 unless defined $version;

    my @need;
    my $type;
    if ( $target == $version ) {
      $Logger->debugf( 'Database is already at migration version %d', $target );
      return 1;
    } elsif ( $target > $version ) {    # upgrade
      $type = 'up';
      $version += 1;
      @need = $version .. $target;
    } else {                            # downgrade
      $type = 'down';
      $target += 1;
      @need = reverse( $target .. $version );
    }
    my $files = $self->_files( $type, \@need );
    if ( defined $files ) {
      for my $file ( @$files ) {
        my $name = $file->{ name };
        my $ver  = $file->{ version };
        $Logger->debugf( "Process migration '%s'", $name );
        my $content   = $name->slurp_raw;
        my $delimiter = ( $content =~ m/\A-- *dbix_migration_delimiter: *([[:graph:]])/ ) ? $1 : ';';
        $Logger->debugf( "Migration section delimiter is '%s'", $delimiter );
        $content =~ s/\s*--.*$//mg;
        # split content into sections ($sql)
        for my $sql ( split /$delimiter/, $content ) {
          $sql =~ s/\A\s*//;
          next unless $sql =~ /\w/;
          $sql = expand_string( $sql, $self->placeholders );
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
      $Logger->debugf( "Database is at version %d, couldn't migrate to version %d", $newver, $target )
        if $target != $newver;
      return 0;
    }
  } catch {
    $fatal_error = $_;
  };

  if ( $fatal_error ) {
    $Logger->debug( 'Rollback transaction turning AutoCommit on again' ), $self->{ _dbh }->rollback
      if exists $self->{ _dbh };
    delete $self->{ _dbh };
    # rethrow exception
    die $fatal_error;
  }
  $Logger->debug( 'Commit transaction turning AutoCommit on again' );
  $self->{ _dbh }->commit;
  delete $self->{ _dbh };

  return $return_value;
}

# overrideable
sub quoted_tracking_table {
  my $self = shift;

  return $self->dbh->quote_identifier( $self->tracking_table );
}

sub version {
  my $self = shift;

  my $dbh = $self->dbh;
  local @{ $dbh }{ qw( RaiseError PrintError ) } = ( 1, 0 );
  try {
    my $tracking_table = $self->quoted_tracking_table;
    $Logger->debugf( "Read tracking table '%s'", $tracking_table );
    my $sth = $dbh->prepare( "SELECT value FROM $tracking_table WHERE name = ?" );
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
        return unless $_->basename =~ m/(?:\A|\D+)${i}_$type\.sql\z/;
        $Logger->debugf( "Found migration '%s'", $_ );
        push @files, { name => $_, version => $i };
      }
    );
  }

  return ( @files and @$need == @files ) ? \@files : undef;
}

sub _initialize_tracking_table {
  my $self = shift;

  my $tracking_table = $self->quoted_tracking_table;
  $Logger->debugf( "Initialize tracking table '%s'", $tracking_table );
  $self->{ _dbh }->do( "INSERT INTO $tracking_table ( name, value ) VALUES ( ?, ? )", undef, 'version', 0 );
}

sub _update_tracking_table {
  my ( $self, $version ) = @_;

  my $tracking_table = $self->quoted_tracking_table;
  $Logger->debugf( "Update tracking table '%s'", $tracking_table );
  $self->{ _dbh }->do( "UPDATE $tracking_table SET value = ? WHERE name = ?", undef, $version, 'version' );
}

1;
