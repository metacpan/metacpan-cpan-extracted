use strict;
use warnings;

package App::runscript;

# keeping the following $VERSION declaration on a single line is important
#<<<
use version 0.9915; our $VERSION = version->declare( '1.0.0' );
#>>>

use subs qw( main _croakf _is_dir _locate_install_lib _prepend_install_lib _which );
use vars qw( @CARP_NOT );

use Config         qw( %Config );
use File::Basename qw( basename dirname );
use File::Spec     qw();
use File::Which    qw( which );
use Getopt::Std    qw( getopts );
use POSIX          qw( EXIT_SUCCESS );

sub main ( \@ ) {
  local @ARGV = @{ $_[ 0 ] };

  my $opts;
  {
    local $SIG{ __WARN__ } = sub {
      local @CARP_NOT = qw( Getopt::Std );
      my $warning = shift;
      chomp $warning;
      _croakf $warning;
    };
    getopts( '-Vh', $opts = {} );
  }
  if ( $opts->{ V } ) {
    print STDOUT "runscript $VERSION\n";
    return EXIT_SUCCESS;
  } elsif ( $opts->{ h } ) {
    print STDOUT "Usage: runscript [ -V | -h  ]\n",
      "       runscript <perl application> <arguments passed to the perl application>\n";
    return EXIT_SUCCESS;
  }

  # derive the pathname of the file containing the perl interpreter
  # https://perldoc.perl.org/perlvar#$%5EX
  my $perl_path = $Config{ perlpath };
  if ( $^O ne 'VMS' ) {
    $perl_path .= $Config{ _exe }
      unless $perl_path =~ m/$Config{ _exe }\z/i;
  }

  exec { $perl_path } ( basename( $perl_path ), _prepend_install_lib( @ARGV ) );
}

sub _croakf ( $@ ) {
  require Carp;
  @_ = ( ( @_ == 1 ? shift : sprintf shift, @_ ) . ', stopped' );
  goto &Carp::croak;
}

sub _is_dir ( $ ) {
  return -d $_[ 0 ];
}

sub _locate_install_lib ( $ ) {
  my ( $application ) = @_;

  my $install_bin = dirname $application;
  _croakf "Basename of '%s' is not 'bin'", $install_bin unless basename( $install_bin ) eq 'bin';

  my $install_base = dirname $install_bin;
  my $install_lib  = File::Spec->catdir( $install_base, qw( lib perl5 ) );

  _croakf "Library path '%s' derived from application '%s' does not exist", $install_lib, $application
    unless _is_dir $install_lib;

  return $install_lib;
}

sub _prepend_install_lib ( @ ) {
  my ( $application ) = @_;

  if ( File::Spec->file_name_is_absolute( $application ) ) {
    _croakf "Script '%s' has no execute permission", $application unless -x $application;
  } else {
    $application = _which $application, 1;
    _croakf "Cannot find application '%s' in PATH (%s)", $_[ 0 ], $ENV{ PATH } unless defined $application;
  }
  shift;

  return ( '-I' . _locate_install_lib( $application ), $application, @_ );
}

sub _which ( $;$ ) {
  my ( $executable, $abs_path ) = @_;

  _croakf 'Cannot locate undefined executable file' unless defined $executable;

  return unless my $file = which $executable;
  if ( $abs_path ) {
    require Cwd;
    return Cwd::abs_path( $file );
  } else {
    return $file;
  }
}

1;
