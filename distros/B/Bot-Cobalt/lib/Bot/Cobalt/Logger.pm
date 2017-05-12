package Bot::Cobalt::Logger;
$Bot::Cobalt::Logger::VERSION = '0.021003';
use strictures 2;
use Carp;

use Bot::Cobalt::Common ':types';
use Bot::Cobalt::Logger::Output;


use Moo;

has level => (
  required  => 1,
  is        => 'ro',
  writer    => 'set_level',
  isa       => Enum[qw/error warn info debug/],
);

## time_format / log_format are passed to ::Output
has time_format => (
  lazy      => 1,
  is        => 'rw',
  isa       => Str,
  predicate => 'has_time_format',
  trigger   => sub {
    my ($self, $val) = @_;
    $self->output->time_format($val) if $self->has_output
  },
);

has log_format => (
  lazy      => 1,
  is        => 'rw',
  isa       => Str,
  predicate => 'has_log_format',
  trigger   => sub {
    my ($self, $val) = @_;
    $self->output->log_format($val) if $self->has_output
  },
);


has output => (
  lazy      => 1,
  is        => 'rwp',
  predicate => 'has_output',
  isa       => InstanceOf['Bot::Cobalt::Logger::Output'],
  builder   => '_build_output',
);

has _levmap => (
  is        => 'ro',
  isa       => HashRef,
  builder   => sub {
    +{
      error => 1,
      warn  => 2,
      info  => 3,
      debug => 4,
    }
  },
);

sub _build_output {
  my ($self) = @_;

  my %opts;

  $opts{log_format}  = $self->log_format  if $self->has_log_format;
  $opts{time_format} = $self->time_format if $self->has_time_format;

  Bot::Cobalt::Logger::Output->new(
    %opts
  )
}

sub _should_log {
  my ($self, $level) = @_;

  my $num_lev = $self->_levmap->{$level}
    || confess "unknown level $level";

  my $accept = $self->_levmap->{ $self->level };

  $accept >= $num_lev ? 1 : 0
}

sub _log_to_level {
  my ($self, $level) = splice @_, 0, 2;

  $self->output->_write(
    $level,
    [ caller(1) ],
    @_
  ) if $self->_should_log($level);

  1
}

sub debug { shift->_log_to_level( 'debug', @_ ) }
sub info  { shift->_log_to_level( 'info', @_ )  }
sub warn  { shift->_log_to_level( 'warn', @_ )  }
sub error { shift->_log_to_level( 'error', @_ ) }

1;

=pod

=head1 NAME

Bot::Cobalt::Logger - Log handler for Bot::Cobalt

=head1 SYNOPSIS

  my $logger = Bot::Cobalt::Logger->new(
    ## Required, one of: debug info warn error
    level => 'info',
  
    ## Optional, passed to Bot::Cobalt::Logger::Output
    time_format => "%Y/%m/%d %H:%M:%S"
    log_format  => "%time% %pkg% (%level%) %msg%"
  );

  ## Add outputs
  ## (See Bot::Cobalt::Logger::Output for details)
  $logger->output->add(
    'Output::File' =>
      { file => $path_to_log },

    'Output::Term' =>
      { },
  );

  ## Log messages
  $logger->debug("Debugging message", @more_info );
  $logger->info("Informative message");
  $logger->warn("Warning message");
  $logger->error("Error message");

=head1 DESCRIPTION

This is the log handler for L<Bot::Cobalt>.

Configured outputs must be added before log messages actually go 
anywhere (see the L</SYNOPSIS>). See L<Bot::Cobalt::Logger::Output> for 
details.

=head2 Log Levels

A B<level> is required at construction-time; messages logged to the 
specified level or any level below it will be recorded.

For example, a B<level> of 'warn' will discard log messages to 'debug' 
and 'info' and report only 'warn' and 'error' messages.

Valid levels, from high to low:

  debug
  info
  warn
  error

These should be called as methods to log to the appropriate level:

  $logger->info("This is some information");

If a list is provided, it will be concatenated with an empty space 
between items:

  $logger->info("Some info", "more info");

=head2 Methods

=head3 level

Returns the currently tracked log level.

=head3 set_level

Changes the current log level.

=head3 time_format

Sets a date/time formatting string to be fed to C<strftime> -- see 
L<Bot::Cobalt::Logger::Output>

=head3 log_format

Sets a formatting template string for log messages -- see 
L<Bot::Cobalt::Logger::Output>

=head3 output

Returns the L<Bot::Cobalt::Logger::Output> object.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
