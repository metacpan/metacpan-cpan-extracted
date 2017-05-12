package Bot::Cobalt::Logger::Output;
$Bot::Cobalt::Logger::Output::VERSION = '0.021003';
use Carp;
use strictures 2;

use Bot::Cobalt::Common qw/:types :string/;
use POSIX ();
use Try::Tiny;

use Moo;

has time_format => (
  is        => 'rw',
  isa       => Str,
  builder   => sub { "%Y-%m-%d %H:%M:%S" },  # strftime
);

has log_format => (
  is        => 'rw',
  isa       => Str,
  builder   => sub { "%level %time (%pkg%) %msg" }, # rplprintf
);


has _outputs => (
  is        => 'rwp',
  isa       => HashRef,
  default   => sub { +{} },
);


sub add {
  my ($self, @args) = @_;
  
  unless (@args && @args % 2 == 0) {
    confess "add() expects an even number of arguments, ",
         "mapping an Output class to a HASH of constructor arguments"
  }
  
  my $prefix = 'Bot::Cobalt::Logger::Output::' ;
  
  CONFIG: while (my ($alias, $opts) = splice @args, 0, 2) {
    confess "Can't add $alias, opts are not a HASH"
      unless ref $opts eq 'HASH';

    confess "Can't add $alias, no type specified"
      unless $opts->{type};

    my $target_pkg = $prefix . delete $opts->{type};

    { local $@;
      eval "require $target_pkg";
      
      if (my $err = $@) {
        carp "Could not add logger $alias: $err";
        next CONFIG
      }
    }

    my $new_obj = try {
      $target_pkg->new(%$opts)
    } catch {
      carp "Could not add logger $alias; new() died: $_";
      undef
    } or next CONFIG;

    $self->_outputs->{$alias} = $new_obj;
  }  ## CONFIG

  1
}

sub del {
  my ($self, @aliases) = @_;
  my $x;

  for my $alias (@aliases) {
    ++$x if delete $self->_outputs->{$alias}
  }

  $x
}

sub get {
  my ($self, $alias) = @_;
  $self->_outputs->{$alias}
}


## Private.
sub _format {
  my ($self, $level, $caller, @strings) = @_;
  
  rplprintf( $self->log_format, {
    level => $level,

    ## Actual message.
    msg  => join(' ', @strings),  

    time => POSIX::strftime( $self->time_format, localtime ),

    pkg  => $caller->[0],
    file => $caller->[1],
    line => $caller->[2],
    sub  => $caller->[3],
  }) . "\n"
}

sub _write {
  my $self = shift;

  for my $alias (keys %{ $self->_outputs }) {
    my $output = $self->_outputs->{$alias};
    $output->_write(
      ## Output classes can provide their own _format
      $output->can('_format') ?  $output->_format( @_ )
        : $self->_format( @_ )
    )
  }

  1
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Logger::Output - Log handler output manager

=head1 SYNOPSIS

  ## Normally constructed by Bot::Cobalt::Logger

  my $log_output = Bot::Cobalt::Logger::Output->new(
    log_format  => $log_format,
    time_format => $time_format,
  );
  
  $log_output->add(
    'my_alias' => {
      type => 'File',
      file => $path_to_log,
    },
  );

=head1 DESCRIPTION

This is the output manager for L<Bot::Cobalt::Logger>, handling dispatch 
to log writers such as L<Bot::Cobalt::Logger::Output::File> and 
L<Bot::Cobalt::Logger::Output::Term>.

=head2 Methods

=head3 add

C<add()> takes a list of aliases to add, mapped to a HASH containing the 
name of their writer class (B<type>) and arguments to pass to the writer 
class constructor:

  $log_output->add(
    ## Add a Bot::Cobalt::Logger::Output::File
    ## new() is passed 'file => $path_to_log'
    MyLogger => {
      type => 'File',
      file => $path_to_log,
    },
    
    ## Add a Logger::Output::Term also:
    Screen => {
      type => 'Term',
    },
  );

The specified outputs will be initialized and tracked; their C<_write> 
method is called when log messages are received.

=head3 del

C<del()> takes a list of aliases to delete.

Returns the number of aliases actually deleted.

=head3 get

C<get()> takes an alias and returns the appropriate writer object (or 
undef).

=head3 log_format

B<log_format> can be specified at construction time or changed on the 
fly.

This is used to specify the actual layout of each individual logged 
message (for the default formatter; specific output classes may choose 
to override the formatter and disregard log_format).

Takes a L<Bot::Cobalt::Utils/rplprintf> template string; normal rplprintf 
usage rules apply -- a replacement sequence starts with '%' and is 
terminated by either a space or a trailing '%'.

Defaults to "%level %time (%pkg%) %msg"

Replacement variables passed in to the template are:

  msg     Actual (concatenated) log message
  level   Level this message was logged to
  time    Current date and time (see time_format)
  pkg     Package this log method was called from
  file    File called from
  line    Line called from
  sub     Subroutine called from

=head3 time_format

B<time_format> can be specified at construction time or changed on the 
fly.

This is used to create the '%time' template variable for L</log_format>.

It is fed to C<strftime> to create a time/date string; see the 
documentation for C<strftime> on your system for a complete list of 
usable replacement sequences.

Defaults to "%Y-%m-%d %H:%M:%S"

Commonly used replacement sequences include:

  %Y   Current year including century.  
  %m   Current month (as a number)
  %d   Current day of the month.

  %A   Full weekday name
  %a   Abbreviated weekday name
  %B   Full month name
  %b   Abbreviated month name

  %H   Hour of the day (on a 24-hour clock)
  %I   Hour of the day (on a 12-hour clock)
  %p   'AM' or 'PM' indication
  %M   Current minute
  %S   Current second
  %Z   Current timezone

  %s   Seconds since epoch ("Unix time")
    
  %%   Literal %

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
