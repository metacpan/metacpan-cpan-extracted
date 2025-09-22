use strict;
use warnings;

package App::Logger;

use Role::Tiny;

use Log::Log4perl;
use Log::Log4perl::Level;

use Readonly;
# log4perl
Readonly::Hash our %LOG_LEVELS => (
  trace => $TRACE,
  debug => $DEBUG,
  warn  => $WARN,
  info  => $INFO,
  error => $ERROR,
);

use parent qw(Class::Accessor::Fast);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(_logger log_level print_error));

########################################################################
sub set_logger {
########################################################################
  my ( $self, $logger ) = @_;

  $self->set__logger($logger);

  return $logger;
}

########################################################################
sub get_logger {
########################################################################
  my ($self) = @_;

  my $logger = $self->get__logger;

  if ( !$logger ) {
    if ( !Log::Log4perl->initialized ) {
      my $log_level = $self->get_log_level // 'info';
      $log_level = $LOG_LEVELS{ lc $log_level } // $INFO;

      my $log4perl_conf = eval { $self->get_log4perl_conf };

      if ($log4perl_conf) {
        Log::Log4perl->initialize( \$log4perl_conf );
      }
      else {
        Log::Log4perl->easy_init($log_level);
      }
    }

    $logger = Log::Log4perl->get_logger;

    $self->set_logger($logger);
  }

  return $logger;
}

package App::Command;

use Carp;
use Data::Dumper;
use English qw(no_match_vars);
use File::Basename qw(basename fileparse dirname);
use File::Temp qw(tempfile tempdir);
use IPC::Run qw(run);
use JSON;
use Readonly;

use Role::Tiny::With;

with 'App::Logger';
with 'App::BenchmarkRole';

Readonly::Scalar our $EMPTY => q{};

use parent qw(Class::Accessor::Fast);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(last_command error error_code last_result));

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  if ( $options->{logger} ) {
    $options->{_logger} = delete $options->{logger};
  }

  return $class->SUPER::new($options);
}

########################################################################
sub execute {
########################################################################
  my ( $self, @cmd ) = @_;

  $self->get_logger->trace( sub { return Dumper( [ cmd => \@cmd ] ) } );

  $self->get_logger->debug( 'execute: ' . join q{ }, @cmd );

  my $out = $EMPTY;

  my $err = $EMPTY;

  $self->set_last_command( \@cmd );

  run( \@cmd, '>', \$out, '2>', \$err );

  my $error_code = $CHILD_ERROR >> 8;

  if ( $err && $self->get_print_error ) {
    $self->log_error( 'execute: exit code:[%d]: error: [%s]', $error_code, $err );
  }

  $self->set_error($err);

  $self->set_error_code($error_code);

  $self->set_last_result($out);

  return $out;
}

1;
