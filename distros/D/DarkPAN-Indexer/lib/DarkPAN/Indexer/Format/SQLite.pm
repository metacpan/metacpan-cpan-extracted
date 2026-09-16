package DarkPAN::Indexer::Format::SQLite;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(choose);
use Carp;
use DBI;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Temp qw(tempfile);
use POSIX qw(strftime);
use Scalar::Util qw(openhandle);

use Role::Tiny::With;
with 'DarkPAN::Indexer::Format';

########################################################################
# Indexers must implement:
########################################################################
#  create_index
#  delete_from_index
#  load_index
#  update_index
#  new
#######################################################################

########################################################################
sub new {
########################################################################
  my ( $class, $config ) = @_;

  $config //= {};

  return bless { config => $config }, $class;
}

########################################################################
sub create_index {
########################################################################
  my ( $self, %args ) = @_;

  my ( $output, $distributions, $fetch ) = @args{qw(output distributions fetch)};

  croak "create_index requires a 'fetch' callback\n"
    if !$fetch;

  my $output_fh = choose {
    return $output
      if openhandle($output);

    return *STDOUT
      if !$output;

    open my $fh, '>', $output
      or die sprintf "unable to open '%s' for writing: %s\n", $output, $OS_ERROR,;

    return $fh;
  };

  my %stats = (
    distributions_seen    => 0,
    distributions_indexed => 0,
    distributions_failed  => 0,
    modules_written       => 0,
  );

  foreach my $key ( @{ $distributions || [] } ) {
    $stats{distributions_seen}++;

    my $module_count
      = eval { return $self->index_distribution( distribution => $key, output_fh => $output_fh, fetch => $fetch ); };

    if ($EVAL_ERROR) {
      my $error = $EVAL_ERROR;
      chomp $error;

      warn sprintf "failed to index %s\n%s", $key, $error;

      $stats{distributions_failed}++;
      next;
    }

    $stats{distributions_indexed}++;
    $stats{modules_written} += $module_count;
  }

  if ( $output && !openhandle($output) ) {
    close $output_fh
      or die sprintf "unable to close '%s': %s\n", $output, $OS_ERROR,;
  }

  printf {*STDERR} "distributions seen: %d, indexed: %d, failed: %d, modules written: %d\n", @stats{
    qw(
      distributions_seen
      distributions_indexed
      distributions_failed
      modules_written
    )
  };

  return \%stats;
}

########################################################################
sub delete_from_index {
########################################################################
  my ( $self, %args ) = @_;

  $self->update_index( %args, delete_only => 1 );
  return;
}

########################################################################
sub load_index {
########################################################################
  my ( $self, %args ) = @_;

  my ( $input, $database, $create, $distribution ) = @args{qw(input database create distribution)};

  croak "input is required\n"
    if !$distribution && ( !defined $input || $input eq q{} );

  croak sprintf "input file '%s' does not exist\n", $input
    if $input && !-e $input;

  if ($create) {
    if ( -e $database ) {
      my $timestamp = strftime '%Y%m%d-%H%M%S', localtime;
      my $backup    = sprintf '%s.%s.bak', $database, $timestamp;
      my $sequence  = 0;

      while ( -e $backup ) {
        $sequence++;
        $backup = sprintf '%s.%s.%d.bak', $database, $timestamp, $sequence;
      }

      rename $database, $backup
        or croak sprintf "unable to back up '%s' to '%s': %s\n", $database, $backup, $OS_ERROR;
    }
  }

  my $dbh = DBI->connect(
    sprintf( 'dbi:SQLite:dbname=%s', $database ),
    q{}, q{},
    { AutoCommit => $FALSE,
      RaiseError => $TRUE,
      PrintError => $FALSE,
    },
  );

  if ($create) {
    $dbh->do(
      q{
      CREATE TABLE modules (
        distribution TEXT NOT NULL,
        module       TEXT NOT NULL,
        version      TEXT NOT NULL
      )
    }
    );

    $dbh->do('CREATE INDEX modules_module_idx ON modules (module)');
    $dbh->do('CREATE INDEX modules_distribution_idx ON modules (distribution)');
  }

  croak "ERROR: no input or distribution\n"
    if !$input && !$distribution;

  my $row_count = eval {
    if ($input) {
      return $self->_load_from_file( $input, $dbh );
    }
    elsif ($distribution) {
      return $self->update_index(
        distribution => $distribution,
        dbh          => $dbh,
        database     => $database,
      );
    }
  };

  my $err = $EVAL_ERROR;

  if ( !$err ) {
    $dbh->commit;
    $dbh->disconnect;
    return $row_count;
  }

  $dbh->rollback;
  $dbh->disconnect;

  croak $err;
}

########################################################################
sub update_index {
########################################################################
  my ( $self, %args ) = @_;

  my ( $distribution, $database, $delete_only, $fetch ) = @args{qw(distribution database delete_only fetch)};

  my $dbh = DBI->connect( "dbi:SQLite:dbname=$database", q{}, q{}, { AutoCommit => 1, RaiseError => 1, PrintError => 0 } );

  $dbh->do( 'delete from modules where distribution = ?', undef, $distribution );
  return if $delete_only;

  my $index = q{};

  open my $output_fh, '>', \$index
    or croak "ERROR: could open scalar \$index for writing\n$OS_ERROR";

  $self->index_distribution(
    fetch        => $fetch,
    distribution => $distribution,
    output_fh    => $output_fh,
  );

  close $output_fh;

  open my $input_fh, '<', \$index ## no critic
    or croak "ERROR: could not open scalar \$index for reading\n$OS_ERROR";

  return $self->_load_from_fh( $input_fh, $dbh );
}

########################################################################
sub _load_from_file {
########################################################################
  my ( $self, $input, $dbh ) = @_;

  open my $input_fh, '<', $input ## no critic
    or die sprintf "unable to open '%s' for reading: %s\n", $input, $OS_ERROR;

  return $self->_load_from_fh( $input_fh, $dbh );
}

########################################################################
sub _load_from_fh {
########################################################################
  my ( $self, $input_fh, $dbh ) = @_;

  my $insert_sth = $dbh->prepare(
    q{
      INSERT INTO modules (distribution, module, version)
      VALUES (?, ?, ?)
    }
  );

  my $rows_loaded = 0;
  my $line_number = 0;

  while ( my $line = <$input_fh> ) {
    $line_number++;
    chomp $line;

    next
      if $line eq q{};

    my ( $distribution, $module, $version, @extra ) = split /\t/x, $line, -1;

    croak sprintf "invalid input at line %d: expected three tab-separated fields\n", $line_number
      if @extra
      || !defined $distribution
      || !defined $module
      || !defined $version
      || $distribution eq q{}
      || $module eq q{}
      || $version eq q{};

    $insert_sth->execute( $distribution, $module, $version );
    $rows_loaded++;
  }

  close $input_fh
    or croak sprintf "unable to close handle: %s\n", $OS_ERROR;

  return $rows_loaded;
}

1;
