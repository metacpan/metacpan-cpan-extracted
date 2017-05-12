package Activator::Log;

require Exporter;
push @ISA, qw( Exporter );
@EXPORT_OK = qw( FATAL ERROR WARN INFO DEBUG TRACE );
%EXPORT_TAGS = ( levels => [ qw( FATAL ERROR WARN INFO DEBUG TRACE ) ] );

use Log::Log4perl;
use Scalar::Util;
use Data::Dumper;
use Activator::Registry;
use base 'Class::StrongSingleton';

=head1 NAME

Activator::Log - provide a simple wrapper for L<Log::Log4perl> for use
within an Activator project.

=head1 SYNOPSIS

  use Activator::Log;
  Activator::Log::WARN( $msg );                # logs to default logger
  Activator::Log->WARN( $msg, $other_logger ); # logs to other logger, don't change default
                                               # NOTE: you MUST use arrow notation!

  use Activator::Log qw( :levels );
  WARN( $msg );

  #### Use alternate default log levels
  Activator::Log->default_level( $level );

  #### Use alternate default loggers
  Activator::Log->default_logger( $logger_name );

=head1 DESCRIPTION

This module provides a simple wrapper for L<Log::Log4perl> that allows
you to have a project level configuration for Log4perl, and have any
class or script in your project be configured and output log messages
in a consistent centralized way.

Additionally, C<TRACE> and C<DEBUG> functions have the extra
capabilities to turn logging on and off on a per-module basis. See the
section L<DISABLING DEBUG OR TRACE BY MODULE> for more information.

=head2 Centralized Configuration

Your project C<log4perl.conf> gets loaded based on your
L<Activator::Registry> configuration. If you do not have a Log4perl
config available, the log level is set to WARN and all output goes to
STDERR.

See the section L<CONFIGURATION> for more details.

=head2 Exporting Level Functions

Log::Log4perl logging functions are exported into the global
namespace if you use the C<:levels> tag

    use Activator::Log qw( :levels );
    &FATAL( $msg );
    &ERROR( $msg );
    &WARN( $msg );
    &INFO( $msg );
    &DEBUG( $msg );
    &TRACE( $msg );

=head2 Static Usage

You can always make static calls to this class no matter how you 'use'
this module:

  Activator::Log->FATAL( $msg );
  Activator::Log->ERROR( $msg );
  Activator::Log->WARN( $msg );
  Activator::Log->INFO( $msg );
  Activator::Log->DEBUG( $msg );
  Activator::Log->TRACE( $msg );

=head2 Using Alternate Loggers

You can set the default logger dynamically:

  Activator::Log->default_logger( 'My.Default.Logger' );

Note that since C<Activator::Log> is a singleton, this sub will set
the level for the entire process. This is probably fine for cron jobs,
not so good for web processes.

You can avoid trouble by logging to an alternate Log4perl logger
without changing the default logger:

  Activator::Log->DEBUG( $msg, 'My.Configured.Debug.Logger' );

=head2 Setting Log Level Dynamically

You can set the minimum level with the C<default_level> sub:

  # only show only levels WARN, ERROR and FATAL
  Activator::Log->default_level( 'WARN' );

  # only show only levels ERROR and FATAL
  Activator::Log->default_level( 'ERROR' );

Note that since C<Activator::Log> is a singleton, this sub will set
the level for the entire process. This is probably fine for cron jobs,
not so good for web processes.

=head2 Additional Functionality provided

The following Log::Log4perl subs you would normally call with
$logger->SUB are supported through a static call:

  Activator::Log->logwarn( $msg );
  Activator::Log->logdie( $msg );
  Activator::Log->error_warn( $msg );
  Activator::Log->error_die( $msg );
  Activator::Log->logcarp( $msg );
  Activator::Log->logcluck( $msg );
  Activator::Log->logcroak( $msg );
  Activator::Log->logconfess( $msg );
  Activator::Log->is_trace()
  Activator::Log->is_debug()
  Activator::Log->is_info()
  Activator::Log->is_warn()
  Activator::Log->is_error()
  Activator::Log->is_fatal()

See the L<Log::Log4perl> documentation for more details.

=head1 CONFIGURATION

=head2 Log::Log4perl

Activator::Log looks in your Registry for a L<Log::Log4perl>
configuration in this heirarchy:

1) A 'log4perl.conf' file in the registry:

  Activator:
    Log:
      log4perl.conf: <file>

2) A 'log4perl' config in the registry:

  Activator:
    Log:
      log4perl:
        'log4perl.key1': 'value1'
        'log4perl.key2': 'value2'
        ... etc.

3) If none of the above are set, C<Activator::Log> defaults to showing WARN level to
C<STDERR> as shown in this log4perl configuration:

  log4perl.logger.Activator.Log = WARN, Screen
  log4perl.appender.Screen = Log::Log4perl::Appender::Screen
  log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.Screen.layout.ConversionPattern = %d{yyyy-mm-dd HH:mm:ss.SSS} [%p] %m (%M %L)%n


NOTE: If C<log4perl.conf> or C<log4perl> is set, it is possible you
will see no logging since L<Log::Log4perl> by default doesn't log
anything. That is, you could have configured this module properly, but
still see no logging.

NOTE 2: You must properly configure L<Log::Log4perl> for this module!

NOTE TO SELF: create a test sub to make life easier

=head2 Setting the Default Logger

Log4Perl can have multiple definitions for loggers. If your script or
program has a preferred logger, set the Registry key c<default_logger>:

  Activator:
    Log:
      default_logger: <logger name IN log4perl.conf>

=head2 Setting the Default Log Level

Set up your registry as such:

  Activator:
    Log:
      default_level: LEVEL

Note that you can also initialize an instance of this module with the
same affect:

  Activator::Log->new( $level );

=head1 DISABLING DEBUG OR TRACE BY MODULE

By default, this module will print all C<DEBUG> and C<TRACE> log messages
provided that the current log level is high enough. However, when
developing it is convenient to be able to turn debugging/tracing on
and off on a per-module basis. The following examples show how to do
this.

=head2 Turn debugging OFF on a per-module basis

  Activator:
    Log:
      DEBUG:
        'My::Module': 0    # My::Module will now prove "silence is bliss"

=head2 Turn debugging ON on a per-module basis

  Activator:
    Log:
      DEBUG:
        FORCE_EXPLICIT: 1
        'My::Module': 1    # only My::Module messages will be debugged
      TRACE:
        FORCE_EXPLICIT: 1
        'Other::Module': 1 # only Other::Module messages will be traced

=head2 Disabling Caveats

Note that the entire Activator framework uses this module, so use
FORCE_EXPLICIT with caution, as you may inadvertantly disable logging
from a package you DO want to hear from.

=head1 USING THIS MODULE IN WRAPPERS

This module respects C<$Log::Log4perl::caller_depth>. When using this
module from a wrapper, you can insure that the message appears to come
from your module as such:

  {
    local $Log::Log4perl::caller_depth;
    $Log::Log4perl::caller_depth += $depth;
    Debug( 'some message' );
  }

You'll likely want to do this in a sub routine if you do a lot of logging.

See also the full description of this technique in "Using
Log::Log4perl from wrapper classes" in the Log4perl FAQ.

=cut

# constructor: implements singleton
sub new {
    my ( $pkg, $level ) = @_;

    my $self = bless( { }, $pkg);

    $self->_init_StrongSingleton();

    if ( Log::Log4perl->initialized() ) {
	# do nothing, logger already set
    }
    else {

	# old config format
	my $config =
	  Activator::Registry->get('Activator::Log') || 
	      Activator::Registry->get('Activator->Log');

	$self->{DEFAULT_LEVEL} =
	  $level ||
	    $config->{default_level} ||
	      'WARN';

	$l4p_config = $ENV{ACT_LOG_log4perl} ||
	  Activator::Registry->get('log4perl.conf') ||
	      Activator::Registry->get('log4perl') ||
		  $config->{'log4perl.conf'} ||
		    $config->{'log4perl'} ||
		      { 'log4perl.logger.Activator.Log' => 'ALL, DEFAULT',
			'log4perl.appender.DEFAULT' => 'Log::Log4perl::Appender::Screen',
			'log4perl.appender.DEFAULT.layout' => 'Log::Log4perl::Layout::PatternLayout',
			'log4perl.appender.DEFAULT.layout.ConversionPattern' => '%d{yyyy-MM-dd HH:mm:ss.SSS} [%p] %m (%M %L)%n',
		      };

	Log::Log4perl->init_once( $l4p_config );
	if ( !Log::Log4perl->initialized() ) {
	    warn( "ERROR: Activator::Log couldn't initialize logger with config $l4p_config");
	}

	$Log::Log4perl::caller_depth++;

	# look for a specific logger to use
	if ( exists $config->{default_logger} ) {
	    # TODO: detect invalid logger config
	    $self->{DEFAULT_LOGGER} = Log::Log4perl->get_logger( $config->{default_logger} );
	}
	else {
	    if ( ! ( $self->{DEFAULT_LOGGER} = Log::Log4perl->get_logger( 'Activator.Log' ) ) ) {
		# they defined a Log4perl config, but no default_logger.
		die q(ERROR: Activator::Log:  If you define 'log4perl' in your registry, you must define 'default_logger' too.);
	    }
	}
    }

    return $self;
}

# backwards compatibility to <1.0
sub level  {
    &default_level( @_ );
}

sub default_level {
    my ( $pkg, $level ) = @_;
    my $self = &new( 'Activator::Log' );
    $level = &_get_static_arg( $pkg, $level );
    $self->{DEFAULT_LOGGER}->level( $level );
}

sub default_logger {
    my ( $pkg, $logger ) = @_;
    my $self = &new( 'Activator::Log' );
    $logger = &_get_static_arg( $pkg, $logger );
    $self->{DEFAULT_LOGGER} = Log::Log4perl->get_logger( $logger )
}

sub FATAL {
    my ( $pkg, $msg, $logger_label ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = &_get_static_arg( $pkg, $msg );
    my $logger = $self->{DEFAULT_LOGGER};
    if ( $logger_label ) {
	$logger = Log::Log4perl->get_logger( $logger_label );
    }
    $logger->fatal( $msg );
}

sub ERROR {
    my ( $pkg, $msg, $logger_label ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = &_get_static_arg( $pkg, $msg );
    my $logger = $self->{DEFAULT_LOGGER};
    if ( $logger_label ) {
	$logger = Log::Log4perl->get_logger( $logger_label );
    }
    $logger->error( $msg );
}
 
sub WARN {
    my ( $pkg, $msg, $logger_label ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = &_get_static_arg( $pkg, $msg );
    my $logger = $self->{DEFAULT_LOGGER};
    if ( $logger_label ) {
	$logger = Log::Log4perl->get_logger( $logger_label );
    }
    $logger->warn( $msg );
}

sub INFO {
    my ( $pkg, $msg, $logger_label ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = &_get_static_arg( $pkg, $msg );
    my $logger = $self->{DEFAULT_LOGGER};
    if ( $logger_label ) {
	$logger = Log::Log4perl->get_logger( $logger_label );
    }
    $logger->info( $msg );
}

sub DEBUG {
    my ( $pkg, $msg, $logger_label ) = @_;
    my $caller = caller;
    my $self = &new( 'Activator::Log' );
    my $debug = &_enabled( 'DEBUG', $caller );
    if ( $debug ) {
       $msg = _get_static_arg( $pkg, $msg );
       my $logger = $self->{DEFAULT_LOGGER};
       if ( $logger_label ) {
	   $logger = Log::Log4perl->get_logger( $logger_label );
       }
       $logger->debug( $msg );
   }
}

sub TRACE {
    my ( $pkg, $msg, $logger_label ) = @_;
    my $caller = caller;
    my $self = &new( 'Activator::Log' );
    my $trace = &_enabled( 'TRACE', $caller );
    if ( $trace ) {
       $msg = _get_static_arg( $pkg, $msg );
       my $logger = $self->{DEFAULT_LOGGER};
       if ( $logger_label ) {
	   $logger = Log::Log4perl->get_logger( $logger_label );
       }
       $logger->trace( $msg );
   }
}


sub is_fatal {
    my $self = &new( 'Activator::Log' );
    return $self->{DEFAULT_LOGGER}->is_fatal();
}

sub is_error {
    my $self = &new( 'Activator::Log' );
    return $self->{DEFAULT_LOGGER}->is_error();
}

sub is_warn {
    my $self = &new( 'Activator::Log' );
    return $self->{DEFAULT_LOGGER}->is_warn();
}

sub is_info {
    my $self = &new( 'Activator::Log' );
    return $self->{DEFAULT_LOGGER}->is_info();
}

sub is_debug {
    my $self = &new( 'Activator::Log' );
    return $self->{DEFAULT_LOGGER}->is_debug();
}

sub is_trace {
    my $self = &new( 'Activator::Log' );
    return $self->{DEFAULT_LOGGER}->is_trace();
}

sub logwarn {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = &_get_static_arg( $pkg, $msg );
    $self->{DEFAULT_LOGGER}->logwarn( $msg );
}

sub logdie {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = &_get_static_arg( $pkg, $msg );
    $self->{DEFAULT_LOGGER}->logdie( $msg );
}

sub error_warn {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = &_get_static_arg( $pkg, $msg );
    $self->{DEFAULT_LOGGER}->error_warn( $msg );
}

sub error_die {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = &_get_static_arg( $pkg, $msg );
    $self->{DEFAULT_LOGGER}->error_die( $msg );
}

sub logcarp {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = &_get_static_arg( $pkg, $msg );B
    $self->{DEFAULT_LOGGER}->logcarp( $msg );
}

sub logcluck {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = &_get_static_arg( $pkg, $msg );
    $self->{DEFAULT_LOGGER}->logcluck( $msg );
}

sub logcroak {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = &_get_static_arg( $pkg, $msg );
    $self->{DEFAULT_LOGGER}->logcroak( $msg );
}

sub logconfess {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = &_get_static_arg( $pkg, $msg );
    $self->{DEFAULT_LOGGER}->logconfess( $msg );
}


sub _enabled {
    my ( $level, $pkg ) = @_;

    return 1 if !$pkg;

    my $log_config = 
      Activator::Registry->get('Activator::Log') || 
	  Activator::Registry->get('Activator->Log');

    my $config = $log_config->{$level};

    my $pkg_setting = -1;
    if (exists( $config->{$pkg} ) &&
	defined( $config->{$pkg} ) ) {
	$pkg_setting = $config->{$pkg};
    }
    my $force_explicit = -1;
    if (exists( $config->{FORCE_EXPLICIT} ) &&
	defined( $config->{FORCE_EXPLICIT} ) ) {
	$force_explicit = $config->{FORCE_EXPLICIT};
    }

    return
      ( $force_explicit == 1 && $pkg_setting == 1 ) ||
	( $force_explicit < 1 && $pkg_setting != 0 ) ||
	  0;
}

# helper to handle static and OO calls
sub _get_static_arg {
    my ( $pkg, $arg ) = @_;

    if ( !$pkg && !$arg ) {
	$arg = '<empty>';
    }
    elsif ( !$arg ) {
	if ( UNIVERSAL::isa( $pkg, 'Activator::Log' ) ) {
	    $arg = '<empty>';
	}
	else {
	    $arg = $pkg;
	}
    }
    chomp $arg;
    return $arg;
}

