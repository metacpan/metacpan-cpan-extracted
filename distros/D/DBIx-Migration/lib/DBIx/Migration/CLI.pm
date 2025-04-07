use strict;
use warnings;

#https://stackoverflow.com/questions/24547252/podusage-help-formatting/24812485#24812485

package DBIx::Migration::CLI;

our $VERSION = $DBIx::Migration::VERSION;

use DBIx::Migration           ();
use Getopt::Std               qw( getopts );
use Log::Any                  ();
use Log::Any::Adapter         ();
use Module::Load::Conditional qw( can_load );
use PerlX::Maybe              qw( maybe );
use POSIX                     qw( EXIT_FAILURE EXIT_SUCCESS );
use Try::Tiny                 qw( catch try );

sub run {
  local @ARGV = @_;

  my $opts;
  my $exitval;
  {
    local $SIG{ __WARN__ } = sub {
      my $warning = shift;
      chomp $warning;
      $exitval = _usage( -exitval => 2, -message => $warning );
    };
    getopts( '-VT:hp:s:t:u:v', $opts = {} );
  }
  return $exitval if defined $exitval;

  if ( $opts->{ V } ) {
    return _usage( -flavour => 'version' );
  } elsif ( $opts->{ h } ) {
    return _usage( -flavour => 'long' );
  }

  return _usage( -exitval => 2, -message => 'Missing mandatory arguments' ) unless @ARGV;

  my $log_any_adapter_entry;
  $log_any_adapter_entry = Log::Any::Adapter->set( { category => qr/\ADBIx::Migration/ }, 'Stderr' )
    if exists $opts->{ v };
  my $Logger = Log::Any->get_logger( category => 'DBIx::Migration' );
  $exitval = try {
    my $dsn    = shift @ARGV;
    my $driver = DBIx::Migration->driver( $dsn );
    my $class  = "DBIx::Migration::$driver";
    $class = 'DBIx::Migration' unless can_load( modules => { $class => undef } );
    $Logger->infof( "Will use '%s' class to process migrations", $class );
    my $m = $class->new(
      dsn => $dsn,
      maybe
        password => $opts->{ p },
      maybe
        username => $opts->{ u },
      maybe
        managed_schema => $opts->{ s },
      maybe
        tracking_schema => $opts->{ t },
      maybe tracking_table => $opts->{ T }
    );
    if ( @ARGV ) {
      $m->dir( shift @ARGV );

      return ( $m->migrate( @ARGV ? shift @ARGV : () ) ? EXIT_SUCCESS : EXIT_FAILURE );
    } else {
      my $version = $m->version;
      print STDOUT ( defined $version ? $version : '' ), "\n";

      return EXIT_SUCCESS;
    }
  } catch {
    chomp;
    return _usage( -exitval => 2, -message => $_ );
  };
  Log::Any::Adapter->remove( $log_any_adapter_entry ) if defined $log_any_adapter_entry;

  return $exitval;
}

sub _usage {
  my %args;
  {
    use warnings FATAL => qw( misc uninitialized );
    %args = ( -exitval => EXIT_SUCCESS, -flavour => 'short', @_ );
  };

  require Pod::Find;
  require Pod::Usage;

  my %sections = ( long => 'SYNOPSIS|OPTIONS|ARGUMENTS', short => 'SYNOPSIS', version => 'VERSION' );
  Pod::Usage::pod2usage(
    -exitval => 'NOEXIT',
    -indent  => 2,
    -input   => Pod::Find::pod_where( { -inc => 1 }, __PACKAGE__ ),
    exists $args{ -message } ? ( -message => $args{ -message } ) : (),
    -output   => ( $args{ -exitval } == EXIT_SUCCESS ) ? \*STDOUT : \*STDERR,
    -sections => $sections{ $args{ -flavour } },
    -verbose  => 99,
    -width    => 120
  );

  return $args{ -exitval };
}

1;
