#!/usr/bin/perl

use strict;
use warnings;

########################################################################
package main;
########################################################################

use Class::Inspector;
use Class::Unload;
use Cwd;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Basename qw(fileparse);
use Getopt::Long qw(:config no_ignore_case);
use List::Util qw(max min);
use Log::Log4perl;
use Log::Log4perl::Level;
use Pod::Usage;
use Proc::Daemon;
use Proc::PID::File;
use Module::Load qw(autoload);

use Amazon::SQS::Config;
use Amazon::SQS::Client;

use Readonly;

Readonly::Scalar our $TRUE  => 1;
Readonly::Scalar our $FALSE => 0;

Readonly::Scalar our $DEFAULT_SLEEP_TIME => 5;
Readonly::Scalar our $MAX_SLEEP_TIME     => 60;
Readonly::Scalar our $APPENDER_NAME      => 'LOGFILE';

Readonly::Scalar our $LOGFILE_CONFIG => <<'END_OF_LOGGER';
log4perl.rootLogger=INFO, LOGFILE
log4perl.appender.LOGFILE=Log::Log4perl::Appender::File
log4perl.appender.LOGFILE.filename=%s
log4perl.appender.LOGFILE.mode=append
log4perl.appender.LOGFILE.layout=PatternLayout
log4perl.appender.LOGFILE.layout.ConversionPattern=%%d (%%r,%%R) (%%p/%%c) [%%P] [%%M:%%L] - %%m%%n
END_OF_LOGGER

Readonly::Scalar our $SCREEN_CONFIG => <<'END_OF_LOGGER';
log4perl.rootLogger=INFO, SCREEN
log4perl.appender.SCREEN=Log::Log4perl::Appender::Screen
log4perl.appender.SCREEN.stderr=%s
log4perl.appender.SCREEN.layout=PatternLayout
log4perl.appender.SCREEN.layout.ConversionPattern=%%d (%%r,%%R) (%%p/%%c) [%%P] [%%M:%%L] - %%m%%n
END_OF_LOGGER

our $KEEP_GOING = $TRUE;
our $RELOAD     = $FALSE;

########################################################################
sub get_options {
########################################################################
  my @option_specs = qw(
    config|c=s
    create-queue|C
    daemonize|d!
    delete-when|D=s
    exit-when|E=s
    endpoint_url|e=s
    help|h
    logfile|L=s
    loglevel|l=s
    max-children|m=i
    max-sleep-time=i
    max-messages=i
    pidfile|p=s
    queue|q=s
    queue-interval|I=i
    handler|H=s
    message-type|M=s
    visibility-timeout|v=i
    wait-time|w=i
  );

  # default options
  my %options = (
    daemonize     => $TRUE,
    'exit-when'   => 'never',
    'delete-when' => 'true',                      # delete message if handled successfully
    handler       => 'Amazon::SQS::QueueHandler',
  );

  my $retval = GetOptions( \%options, @option_specs );

  if ( !$retval || $options{help} ) {
    pod2usage(1);
  }

  die "set 'wait-time' or 'queue-interval' but not both\n"
    if $options{'wait-time'} && $options{'queue-interval'};

  return %options;
}

########################################################################
sub main {
########################################################################

  my %options = get_options();

  die sprintf "no such file %s\n", $options{config}
    if $options{config} && ( !-e $options{config} || !-r $options{config} );

  my $config = load_config( \%options );

  if ( !defined $options{'wait-time'} && !defined $options{'queue-interval'} ) {
    $options{'queue-interval'} = $DEFAULT_SLEEP_TIME;
  }

  if ( $options{'queue-interval'} && !defined $options{'max-sleep-time'} ) {
    $options{'max-sleep-time'} = $MAX_SLEEP_TIME;
  }

  my $logger = init_logger( \%options );

  $logger->trace(
    Dumper(
      [ config  => $config,
        options => \%options
      ]
    )
  );

  # instantiate Amazon::SQS::QueueHandler class
  my $handler = eval { return load_handler( config => $config, options => \%options, logger => $logger ); };

  if ( !$handler || $EVAL_ERROR ) {
    my $err = $EVAL_ERROR;
    if ( ref $err ) {
      die sprintf
        "\rERROR: could not instantiate handler:\nMessage:\t[%s]\nCode:\t\t[%s]\nHTTP Response:\t[%s]\n",
        $err->getMessage,
        $err->getErrorCode,
        $err->getHTTPError;
    }
    elsif ($err) {
      die "ERROR: could not instantiate handler:\n$err";
    }
    else {
      die "ERROR: could not instantiate handler\n";
    }
  }

  # set up signal handlers
  setup_signal_handlers( \%options, \$handler );

  my $service = $handler->get_service;

  if ( $options{daemonize} ) {
    my @dont_close_fh;

    if ( $options{logfile} && $options{logfile} !~ /(?:stderr|stdout)/ixsm ) {
      my $appender = Log::Log4perl->appender_by_name($APPENDER_NAME);
      push @dont_close_fh, $appender->{fh};
    }

    push @dont_close_fh, 'STDERR';
    push @dont_close_fh, 'STDOUT';

    my %daemon_config = (
      work_dir => cwd,
      @dont_close_fh ? ( dont_close_fh => \@dont_close_fh ) : (),
    );

    Proc::Daemon->new(%daemon_config)->Init();

    my %pidfile;

    if ( $config && $config->get_handler_pidfile ) {
      my ( $name, $path, $ext ) = fileparse( $config->get_handler_pidfile, qr/[.][^.]+$/xsm );
      $pidfile{dir} = $path;
      $ext //= 'pid';
      $pidfile{name} = sprintf '%s.%s', $name, $ext;
    }

    # If already running, then exit
    if ( Proc::PID::File->running(%pidfile) ) {
      $logger->error('already running...');
      exit 0;
    }
  }

  my $sleep;

  while ($KEEP_GOING) {

    if ( !$sleep || $RELOAD ) {
      $sleep  = $options{'queue-interval'};
      $RELOAD = $FALSE;
    }

    $logger->info( sprintf 'reading queue: %s', $handler->get_url );

    my $message = eval {
      my $message = $handler->get_next_message();

      return $message
        if $message;

      die $EVAL_ERROR
        if $EVAL_ERROR;

      $logger->info('no messages...');

      if ( !$handler->get_wait_time ) {
        $logger->info( sprintf '...sleeping for %d seconds', $sleep );
        sleep $sleep;

        $sleep = min( $options{'max-sleep-time'}, sleep_time( $sleep, \%options ) );
      }

      return;
    };

    my $err = $EVAL_ERROR;

    next
      if !$message && !$err;

    undef $sleep;

    my $retval = eval {
      die Dumper( [ error => $err ] )
        if $err;

      $logger->info( 'processing messsage (%s)...', $handler->get_message_id );

      return $handler->handler($message);
    };

    $err = $EVAL_ERROR;

    if ( !$retval || $err ) {
      $logger->error( sprintf "message error...\n%s", ref $err ? Dumper($err) : $err );

      # exit immediately if BAD REQUEST or INTERNAL SERVER ERROR
      if ( $err && ref $err && $err->getStatusCode =~ /(?:400|500)/xsm ) {
        exit 1;
      }

      next
        if !$handler->get_message();

      # handle message disposition
      if ($err) {
        if ( $options{'delete-when'} =~ /(?:error|always)/xsm ) {
          $logger->info('deleting message');
          $handler->delete_message();
        }

        if ( $options{'exit-when'} =~ /(?:error|always)/xsm ) {
          $KEEP_GOING = $FALSE;
        }
      }
      else {
        if ( $options{'delete-when'} =~ /(?:false|always)/xsm ) {
          $logger->info('deleting message');
          $handler->delete_message();
        }

        if ( $options{'exit-when'} =~ /(?:always|false)/xsm ) {
          $KEEP_GOING = $FALSE;
        }
      }
    }
    else {
      $logger->info( sprintf 'message (%s) handled successfully', $handler->get_message_id );

      if ( $options{'delete-when'} =~ /(?:always|true)/xsm ) {
        $logger->info('deleting message');
        $handler->delete_message();
      }
    }

    if ( $options{'exit-when'} eq 'always' ) {
      $KEEP_GOING = $FALSE;
    }
  }

  return 0;
}

########################################################################
sub init_logger {
########################################################################
  my ($options) = @_;

  my ( $logfile, $loglevel ) = @{$options}{qw(logfile loglevel)};

  $loglevel //= 'info';

  $loglevel = {
    error => $ERROR,
    debug => $DEBUG,
    trace => $TRACE,
    info  => $INFO,
    warn  => $WARN,
  }->{ lc $loglevel };

  $loglevel //= $INFO;

  $logfile //= 'stderr';

  my $log4perl_config;

  if ( !$logfile || $logfile =~ /(?:stderr|stdout)/xsmi ) {
    $log4perl_config    = sprintf $SCREEN_CONFIG, $logfile eq 'stdout' ? 0 : 1;
    $options->{logfile} = lc $logfile;
  }
  else {
    $log4perl_config = sprintf $log4perl_config, $logfile;
  }

  if ( Log::Log4perl->initialized() ) {
    my $logger = Log::Log4perl->get_logger;
    $logger->level($loglevel);
    return $logger;
  }

  Log::Log4perl->init( \$log4perl_config );

  my $logger = Log::Log4perl->get_logger;
  $logger->level($loglevel);

  return $logger;
}

########################################################################
sub setup_signal_handlers {
########################################################################
  my ( $options, $handler ) = @_;

  $SIG{HUP} = sub {
    print {*STDERR} "Caught SIGHUP:  re-reading config file.\n";

    $KEEP_GOING = $TRUE;

    my $config = load_config($options);

    ${$handler} = load_handler(
      options     => $options,
      logger      => ${$handler}->get_logger,
      credentials => ${$handler}->get_credentials,
      config      => $config,
    );

    init_logger($options);  # just reset loglevel (potentially)

    $RELOAD = $TRUE;
  };

  $SIG{INT} = sub {
    print {*STDERR} ("Caught SIGINT:  exiting gracefully\n");
    $KEEP_GOING = $FALSE;
  };

  $SIG{QUIT} = sub {
    print {*STDERR} ("Caught SIGQUIT:  exiting gracefully\n");
    $KEEP_GOING = $FALSE;
  };

  $SIG{TERM} = sub {
    print {*STDERR} ("Caught SIGTERM:  exiting gracefully\n");
    $KEEP_GOING = $FALSE;
  };

  return;
}

########################################################################
sub load_config {
########################################################################
  my ($options) = @_;

  return
    if !$options->{config};

  my $config = Amazon::SQS::Config->new( file => $options->{config} );

  $options->{loglevel} //= $config->get_log_level;

  $options->{logfile} //= $config->get_log_file;
  $options->{logfile} //= 'stderr';

  $options->{'delete-when'} //= $config->get_error_delete;

  $options->{'exit-when'} //= $config->get_error_exit;

  $options->{handler} //= $config->get_handler_class;

  $options->{'max-sleep-time'} //= $config->get_queue_max_wait;

  $options->{'max-messages'} //= $config->get_queue_max_messages // 1;

  $options->{queue} //= $config->get_queue_name;

  $options->{'queue-url'} //= $config->get_queue_url;

  $options->{'queue-interval'} //= $config->get_queue_interval;

  $options->{'create-queue'} //= $config->get_queue_create_queue // $FALSE;

  $options->{'visibility-timeout'} //= $config->get_queue_visibility_timeout;

  $options->{'wait-time'} //= $config->get_queue_wait_time;

  return $config;
}

########################################################################
sub load_handler {
########################################################################
  my %args = @_;

  my ( $config, $options, $logger, $credentials ) = @args{qw(config options logger credentials)};

  if ( Class::Inspector->loaded( $options->{handler} ) ) {
    Class::Unload->unload( $options->{handler} );
  }

  autoload $options->{handler};

  my $handler = $options->{handler}->new(
    config             => $config,
    logger             => $logger,
    endpoint_url       => $options->{endpoint_url},
    name               => $options->{queue},
    url                => $options->{'queue-url'},
    message_type       => $options->{'message-type'},
    create_queue       => $options->{'create-queue'},
    wait_time          => $options->{'wait-time'},
    visibility_timeout => $options->{'visibility-timeout'},
    credentials        => $credentials,
  );

  die "not an Amazon::SQS::QueueHandler\n"
    if !$handler->isa('Amazon::SQS::QueueHandler');

  return $handler;
}

########################################################################
sub sleep_time {
########################################################################
  my ( $sleep, $options ) = @_;

  $sleep //= 0;

  return $sleep + $options->{'queue-interval'};
}

exit main();

1;

__END__

=pod

=head1 NAME 

QueueDaemon.pl - wrapper for queue handler daemons

=head1 SYNOPSIS

 QueueDaemon.pl options

Read and process SQS messages.

=head1 DESCRIPTION

Implements a daemon that reads from Amazon's Simple Queue Service
(SQS).

=head1 OPTIONS

 -h, --help               help
 -c, --config             config file name
 -C, --create-queue       create the queue if it does not exist
 -d, --daemonize          daemonize the script (default)
     --no-daemonize       
 -D, --delete-when        never, always, error
 -E, --exit-when          never, always, error, false
 -e, --endpoint-url       default: https://sqs.amazonaws.com
 -L, --logfile            name of logfile
 -l, --loglevel           log level (trace, debug, info, warn, error)
 -H, --handler            name of the handler class, default: Amazon::SQS::QueueHandler
 -m, --max-children       not implemented (default: 1)
 -s, --max-sleep-time     default: 5 seconds
     --max-messages       fixed at 1 currently
 -M, --message-type       mime type of messages (text/plain, application/json, 
                          application/x-www-form-encoded), default: text/plain
 -q, --queue              queue name (not url)
     --queue-interval     amount of time to sleep
 -p, --pidfile            fully qualified path of pid file, default: /var/run/QueueDaemon.pl.in
 -v, --visibility-timeout visibility timeout in seconds, default: 30
 -w, --wait-time          long polling wait time in seconds, default: 0

=head2 LICENSE

(c) Copyright 2024 TBC Development Group, LLC. All rights reserved.
This is free software and may be used or distributed under the same terms as Perl itself.

=head1 FEATURES

=over 5

=item * easy configuration using the command line options or a configuration file

=item * automatically create a queue if it doesn't exist

=item * long or short polling. Set --wait-time for long polling, --queue-interval for short polling

=item * configurable message disposition options for successful handling of messages and exceptions

=item * can be run as a daemon or in a terminal

=back

=head1 HINTS & TIPS

=head2 Quick Start

 QueueDaemon.pl --create-queue -q fooManQueue

=over 5 

=item 1. If the queue does not exist it will be created if you use the --create-queue option.

=item 2. If no logfile is given, log output will be sent to STDERR

=item 3. See L<Amazon::SQS::Config> regarding the available options in a config file.

=item 4. The default is to daemonize the script. Use --no-daemonize to run in a terminal.

=item 5. If you do not provide a handler on the command line or in
your .ini file the default handler will be used. The default hanlder will dump the
message to the log and delete the message.

=item 6. By default messages will only be deleted from the queue if your
handler returns a true value. If you want to delete messages which cannot be
decoded or when you handler returns a non-true value, set the
--delete-when or set 'delete' option in the [error] section of your .ini file.

=item 7. To exit the daemon when your handler returns a non-true value
set the --exit-when option to 'false' or in the [error] section of your .ini
file, set 'exit = false'.

=item 8. To exit the daemon if your handler throws an exception, 
set the --exit-when option to 'error' or in the [error] section of your .ini
file, set 'exit = error'.

=back

The daemon can be started using the helper script C<aws-sqsd>.

=over 5

=item Starting

By default the startup script will look for the script
(C<QueueDaemon.pl>) and the configuration file (C<aws-sqs.ini>) in all
of the places where they should have been installed regardless of
whether you installed the program as a CPAN distribution or manually
(C<./configure && make && make install>).  If you've relocated the
program or the configuration file you use environment variables to
tell the startup script where to look for these artifacts.

=over 10

=item CONFIG - fully qualified path the configuration file

=item DAEMON - fully qualified path to the C<QueueDaemon.pl> script.

=back

 sudo CONFIG=/etc/myapp/aws-sqs.ini aws-sqsd start

=item Stopping

 sudo /sbin/service aws-sqsd stop

=item Restarting

 $ sudo /sbin/service aws-sqsd restart

=item Rereading Config file after changes

 $ sudo /sbin/service aws-sqsd graceful

=back

=head1 CONFIGURATION

See L</Amazon::SQS::Config>

=cut

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=head1 SEE ALSO

L<Proc::Daemon>, L<Amazon::SQS::Config>, L<Amazon::SQS::Client>

=cut
