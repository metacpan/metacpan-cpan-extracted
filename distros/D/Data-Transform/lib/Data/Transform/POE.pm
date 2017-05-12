package Data::Transform::POE;
=head1 NAME

Data::Transform::POE

=head1 DESCRIPTION

This is a helper package for using Data::Transform with POE. Currently
it provides an alternate version of POE::Wheel::ReadWrite that makes
that package work with Data::Transform. The only change is that handling
of Data::Transform::Meta packets is now supported.

Load this after you've loaded POE::Wheel::ReadWrite, so it will override
what is in there.

Hopefully this can go away as soon as possible

=cut

package # hide from CPAN indexer
        POE::Wheel::ReadWrite;

use strict;

#use vars qw($VERSION);
#$VERSION = do {my($r)=(q$Revision$=~/(\d+)/);sprintf"1.%04d",$r};
#
use Carp qw( croak carp );
use Scalar::Util qw(blessed);
use POE qw(Wheel Driver::SysRW Filter::Line);

# Offsets into $self.
sub HANDLE_INPUT               () {  0 }
sub HANDLE_OUTPUT              () {  1 }
sub FILTER_INPUT               () {  2 }
sub FILTER_OUTPUT              () {  3 }
sub DRIVER_BOTH                () {  4 }
sub EVENT_INPUT                () {  5 }
sub EVENT_ERROR                () {  6 }
sub EVENT_FLUSHED              () {  7 }
sub WATERMARK_WRITE_MARK_HIGH  () {  8 }
sub WATERMARK_WRITE_MARK_LOW   () {  9 }
sub WATERMARK_WRITE_EVENT_HIGH () { 10 }
sub WATERMARK_WRITE_EVENT_LOW  () { 11 }
sub WATERMARK_WRITE_STATE      () { 12 }
sub DRIVER_BUFFERED_OUT_OCTETS () { 13 }
sub STATE_WRITE                () { 14 }
sub STATE_READ                 () { 15 }
sub UNIQUE_ID                  () { 16 }
sub AUTOFLUSH                  () { 17 }

sub CRIMSON_SCOPE_HACK ($) { 0 }

#------------------------------------------------------------------------------

sub new {
  my $type = shift;
  my %params = @_;

  croak "wheels no longer require a kernel reference as their first parameter"
    if (@_ && (ref($_[0]) eq 'POE::Kernel'));

  croak "$type requires a working Kernel" unless defined $poe_kernel;

  my ($in_handle, $out_handle);
  if (defined $params{Handle}) {
    carp "Ignoring InputHandle parameter (Handle parameter takes precedence)"
      if defined $params{InputHandle};
    carp "Ignoring OutputHandle parameter (Handle parameter takes precedence)"
      if defined $params{OutputHandle};
    $in_handle = $out_handle = delete $params{Handle};
  }
  else {
    croak "Handle or InputHandle required"
      unless defined $params{InputHandle};
    croak "Handle or OutputHandle required"
      unless defined $params{OutputHandle};
    $in_handle  = delete $params{InputHandle};
    $out_handle = delete $params{OutputHandle};
  }

  my ($in_filter, $out_filter);
  if (defined $params{Filter}) {
    carp "Ignoring InputFilter parameter (Filter parameter takes precedence)"
      if (defined $params{InputFilter});
    carp "Ignoring OutputFilter parameter (Filter parameter takes precedence)"
      if (defined $params{OutputFilter});
    $in_filter = $out_filter = delete $params{Filter};
  }
  else {
    $in_filter = delete $params{InputFilter};
    $out_filter = delete $params{OutputFilter};

    # If neither Filter, InputFilter or OutputFilter is defined, then
    # they default to POE::Filter::Line.
    unless (defined $in_filter and defined $out_filter) {
      my $new_filter = POE::Filter::Line->new();
      $in_filter = $new_filter unless defined $in_filter;
      $out_filter = $new_filter unless defined $out_filter;
    }
  }

  my $driver = delete $params{Driver};
  $driver = POE::Driver::SysRW->new() unless defined $driver;

  { my $mark_errors = 0;
    if (defined($params{HighMark}) xor defined($params{LowMark})) {
      carp "HighMark and LowMark parameters require each-other";
      $mark_errors++;
    }
    # Then they both exist, and they must be checked.
    elsif (defined $params{HighMark}) {
      unless (defined($params{HighMark}) and defined($params{LowMark})) {
        carp "HighMark and LowMark parameters must both be defined";
        $mark_errors++;
      }
      unless (($params{HighMark} > 0) and ($params{LowMark} > 0)) {
        carp "HighMark and LowMark parameters must be above 0";
        $mark_errors++;
      }
    }
    if (defined($params{HighMark}) xor defined($params{HighEvent})) {
      carp "HighMark and HighEvent parameters require each-other";
      $mark_errors++;
    }
    if (defined($params{LowMark}) xor defined($params{LowEvent})) {
      carp "LowMark and LowEvent parameters require each-other";
      $mark_errors++;
    }
    croak "Water mark errors" if $mark_errors;
  }

  my $self = bless [
    $in_handle,                       # HANDLE_INPUT
    $out_handle,                      # HANDLE_OUTPUT
    $in_filter,                       # FILTER_INPUT
    $out_filter,                      # FILTER_OUTPUT
    $driver,                          # DRIVER_BOTH
    delete $params{InputEvent},       # EVENT_INPUT
    delete $params{ErrorEvent},       # EVENT_ERROR
    delete $params{FlushedEvent},     # EVENT_FLUSHED
    # Water marks.
    delete $params{HighMark},         # WATERMARK_WRITE_MARK_HIGH
    delete $params{LowMark},          # WATERMARK_WRITE_MARK_LOW
    delete $params{HighEvent},        # WATERMARK_WRITE_EVENT_HIGH
    delete $params{LowEvent},         # WATERMARK_WRITE_EVENT_LOW
    0,                                # WATERMARK_WRITE_STATE
    # Driver statistics.
    0,                                # DRIVER_BUFFERED_OUT_OCTETS
    # Dynamic state names.
    undef,                            # STATE_WRITE
    undef,                            # STATE_READ
    # Unique ID.
    &POE::Wheel::allocate_wheel_id(), # UNIQUE_ID
    delete $params{AutoFlush},         # AUTOFLUSH
  ], $type;

  if (scalar keys %params) {
    carp(
      "unknown parameters in $type constructor call: ",
      join(', ', keys %params)
    );
  }

  $self->_define_read_state();
  $self->_define_write_state();

  return $self;
}

#------------------------------------------------------------------------------
# Redefine the select-write handler.  This uses stupid closure tricks
# to prevent keeping extra references to $self around.

sub _define_write_state {
  my $self = shift;

  # Read-only members.  If any of these change, then the write state
  # is invalidated and needs to be redefined.
  my $driver        = $self->[DRIVER_BOTH];
  my $high_mark     = $self->[WATERMARK_WRITE_MARK_HIGH];
  my $low_mark      = $self->[WATERMARK_WRITE_MARK_LOW];
  my $event_error   = \$self->[EVENT_ERROR];
  my $event_flushed = \$self->[EVENT_FLUSHED];
  my $event_high    = \$self->[WATERMARK_WRITE_EVENT_HIGH];
  my $event_low     = \$self->[WATERMARK_WRITE_EVENT_LOW];
  my $unique_id     = $self->[UNIQUE_ID];

  # Read/write members.  These are done by reference, to avoid pushing
  # $self into the anonymous sub.  Extra copies of $self are bad and
  # can prevent wheels from destructing properly.
  my $is_in_high_water_state     = \$self->[WATERMARK_WRITE_STATE];
  my $driver_buffered_out_octets = \$self->[DRIVER_BUFFERED_OUT_OCTETS];

  # Register the select-write handler.

  $poe_kernel->state(
    $self->[STATE_WRITE] = ref($self) . "($unique_id) -> select write",
    sub {                             # prevents SEGV
      0 && CRIMSON_SCOPE_HACK('<');
                                      # subroutine starts here
      my ($k, $me, $handle) = @_[KERNEL, SESSION, ARG0];

      $$driver_buffered_out_octets = $driver->flush($handle);

      # When you can't write, nothing else matters.
      if ($!) {
        $$event_error && $k->call(
          $me, $$event_error, 'write', ($!+0), $!, $unique_id
        );
        $k->select_write($handle);
      }

      # Could write, or perhaps couldn't but only because the
      # filehandle's buffer is choked.
      else {

        # In high water state?  Check for low water.  High water
        # state will never be set if $event_low is undef, so don't
        # bother checking its definedness here.
        if ($$is_in_high_water_state) {
          if ( $$driver_buffered_out_octets <= $low_mark ) {
            $$is_in_high_water_state = 0;
            $k->call( $me, $$event_low, $unique_id ) if defined $$event_low;
          }
        }

        # Not in high water state.  Check for high water.  Needs to
        # also check definedness of $$driver_buffered_out_octets.
        # Although we know this ahead of time and could probably
        # optimize it away with a second state definition, it would
        # be best to wait until ReadWrite stabilizes.  That way
        # there will be only half as much code to maintain.
        elsif (
          $high_mark and
          ( $$driver_buffered_out_octets >= $high_mark )
        ) {
          $$is_in_high_water_state = 1;
          $k->call( $me, $$event_high, $unique_id ) if defined $$event_high;
        }
      }

      # All chunks written; fire off a "flushed" event.  This
      # occurs independently, so it's possible to get a low-water
      # call and a flushed call at the same time (if the low mark
      # is 1).
      unless ($$driver_buffered_out_octets) {
        $k->select_pause_write($handle);
        $$event_flushed && $k->call($me, $$event_flushed, $unique_id);
      }
    }
 );

  $poe_kernel->select_write($self->[HANDLE_OUTPUT], $self->[STATE_WRITE]);

  # Pause the write select immediately, unless output is pending.
  $poe_kernel->select_pause_write($self->[HANDLE_OUTPUT])
    unless ($self->[DRIVER_BUFFERED_OUT_OCTETS]);
}

#------------------------------------------------------------------------------
# Redefine the select-read handler.  This uses stupid closure tricks
# to prevent keeping extra references to $self around.

sub _define_read_state {
  my $self = shift;

  # Register the select-read handler.

  if (defined $self->[EVENT_INPUT]) {

    # If any of these change, then the read state is invalidated and
    # needs to be redefined.

    my $driver       = $self->[DRIVER_BOTH];
    my $input_filter = \$self->[FILTER_INPUT];
    my $event_input  = \$self->[EVENT_INPUT];
    my $handle_output = $self->[HANDLE_OUTPUT];
    my $event_error  = \$self->[EVENT_ERROR];
    my $unique_id    = $self->[UNIQUE_ID];

    # If the filter can get_one, then define the input state in terms
    # of get_one_start() and get_one().

    if (
      $$input_filter->can('get_one') and
      $$input_filter->can('get_one_start')
    ) {
      $poe_kernel->state(
        $self->[STATE_READ] = ref($self) . "($unique_id) -> select read",
        sub {

          # Protects against coredump on older perls.
          0 && CRIMSON_SCOPE_HACK('<');

          # The actual code starts here.
          my ($k, $me, $handle) = @_[KERNEL, SESSION, ARG0];
          if (defined(my $raw_input = $driver->get($handle))) {
            $$input_filter->get_one_start($raw_input);
            while (1) {
              my $next_rec = $$input_filter->get_one();
              last unless @$next_rec;
              foreach my $cooked_input (@$next_rec) {
                if (blessed ($cooked_input)) {
                  if ($cooked_input->isa('Data::Transform::Meta::SENDBACK')) {
                    $driver->put([$cooked_input->data]);
                    $k->select_resume_write($handle_output);
                    next;
                  }
                }
                $k->call($me, $$event_input, $cooked_input, $unique_id);
              }
            }
          }
          else {
            $$event_error and $k->call(
              $me, $$event_error, 'read', ($!+0), $!, $unique_id
            );
            $k->select_read($handle);
          }
        }
      );
    }

    # Otherwise define the input state in terms of the older, less
    # robust, yet faster get().

    else {
      $poe_kernel->state(
        $self->[STATE_READ] = ref($self) . "($unique_id) -> select read",
        sub {

          # Protects against coredump on older perls.
          0 && CRIMSON_SCOPE_HACK('<');

          # The actual code starts here.
          my ($k, $me, $handle) = @_[KERNEL, SESSION, ARG0];
          if (defined(my $raw_input = $driver->get($handle))) {
            foreach my $cooked_input (@{$$input_filter->get($raw_input)}) {
              $k->call($me, $$event_input, $cooked_input, $unique_id);
            }
          }
          else {
            $$event_error and $k->call(
              $me, $$event_error, 'read', ($!+0), $!, $unique_id
            );
            $k->select_read($handle);
          }
        }
      );
    }
                                        # register the state's select
    $poe_kernel->select_read($self->[HANDLE_INPUT], $self->[STATE_READ]);
  }
                                        # undefine the select, just in case
  else {
    $poe_kernel->select_read($self->[HANDLE_INPUT])
  }
}

#------------------------------------------------------------------------------
# Redefine events.

sub event {
  my $self = shift;
  push(@_, undef) if (scalar(@_) & 1);

  my ($redefine_read, $redefine_write) = (0, 0);

  while (@_) {
    my ($name, $event) = splice(@_, 0, 2);

    if ($name eq 'InputEvent') {
      $self->[EVENT_INPUT] = $event;
      $redefine_read = 1;
    }
    elsif ($name eq 'ErrorEvent') {
      $self->[EVENT_ERROR] = $event;
      $redefine_read = $redefine_write = 1;
    }
    elsif ($name eq 'FlushedEvent') {
      $self->[EVENT_FLUSHED] = $event;
      $redefine_write = 1;
    }
    elsif ($name eq 'HighEvent') {
      if (defined $self->[WATERMARK_WRITE_MARK_HIGH]) {
        $self->[WATERMARK_WRITE_EVENT_HIGH] = $event;
        $redefine_write = 1;
      }
      else {
        carp "Ignoring HighEvent (there is no high watermark set)";
      }
    }
    elsif ($name eq 'LowEvent') {
      if (defined $self->[WATERMARK_WRITE_MARK_LOW]) {
        $self->[WATERMARK_WRITE_EVENT_LOW] = $event;
        $redefine_write = 1;
      }
      else {
        carp "Ignoring LowEvent (there is no high watermark set)";
      }
    }
    else {
      carp "ignoring unknown ReadWrite parameter '$name'";
    }
  }

  $self->_define_read_state()  if $redefine_read;
  $self->_define_write_state() if $redefine_write;
}

#------------------------------------------------------------------------------

sub DESTROY {
  my $self = shift;

  # Turn off the select.  This is a problem if a wheel is being
  # swapped, since it will turn off selects for the other wheel.
  if ($self->[HANDLE_INPUT]) {
    $poe_kernel->select($self->[HANDLE_INPUT]);
    $self->[HANDLE_INPUT] = undef;
  }

  if ($self->[HANDLE_OUTPUT]) {
    $poe_kernel->select($self->[HANDLE_OUTPUT]);
    $self->[HANDLE_OUTPUT] = undef;
  }

  if ($self->[STATE_READ]) {
    $poe_kernel->state($self->[STATE_READ]);
    $self->[STATE_READ] = undef;
  }

  if ($self->[STATE_WRITE]) {
    $poe_kernel->state($self->[STATE_WRITE]);
    $self->[STATE_WRITE] = undef;
  }

  &POE::Wheel::free_wheel_id($self->[UNIQUE_ID]);
}

#------------------------------------------------------------------------------
# TODO - We set the high/low watermark state here, but we don't fire
# events for it.  My assumption is that the return value tells us
# all we want to know.

sub put {
  my ($self, @chunks) = @_;

  my $old_buffered_out_octets = $self->[DRIVER_BUFFERED_OUT_OCTETS];
  my $new_buffered_out_octets;

  if ($self->[FILTER_OUTPUT]->can('meta')) {
    my @filtered_chunks = grep {
      not blessed $_ or not $_->isa('Data::Transform::Meta');
    } @{$self->[FILTER_OUTPUT]->put(\@chunks)};
    $new_buffered_out_octets =
      $self->[DRIVER_BUFFERED_OUT_OCTETS] =
      $self->[DRIVER_BOTH]->put(\@filtered_chunks);
  } else {
    $new_buffered_out_octets =
      $self->[DRIVER_BUFFERED_OUT_OCTETS] =
      $self->[DRIVER_BOTH]->put(
        $self->[FILTER_OUTPUT]->put([
          grep {
            not (blessed $_ and $_->isa('Data::Transform::Meta::EOF'));
          } @chunks
        ])
      );
  }

  if (
    $self->[AUTOFLUSH] &&
    $new_buffered_out_octets and !$old_buffered_out_octets
  ) {
    $old_buffered_out_octets = $new_buffered_out_octets;
    $self->flush();
    $new_buffered_out_octets = $self->[DRIVER_BUFFERED_OUT_OCTETS];
  }

  # Resume write-ok if the output buffer gets data.  This avoids
  # redundant calls to select_resume_write(), which is probably a good
  # thing.
  if ($new_buffered_out_octets and !$old_buffered_out_octets) {
    $poe_kernel->select_resume_write($self->[HANDLE_OUTPUT]);
  }

  # If the high watermark has been reached, return true.
  if (
    $self->[WATERMARK_WRITE_MARK_HIGH] and
    $new_buffered_out_octets >= $self->[WATERMARK_WRITE_MARK_HIGH]
  ) {
    return $self->[WATERMARK_WRITE_STATE] = 1;
  }

  return $self->[WATERMARK_WRITE_STATE] = 0;
}

#------------------------------------------------------------------------------
# Redefine filter. -PG / Now that there are two filters internally,
# one input and one output, make this set both of them at the same
# time. -RCC

sub _transfer_input_buffer {
  my ($self, $buf) = @_;

  my $old_input_filter = $self->[FILTER_INPUT];

  # If the new filter implements "get_one", use that.
  if (
    $old_input_filter->can('get_one') and
    $old_input_filter->can('get_one_start')
  ) {
    if (defined $buf) {
      $self->[FILTER_INPUT]->get_one_start($buf);
      while ($self->[FILTER_INPUT] == $old_input_filter) {
        my $next_rec = $self->[FILTER_INPUT]->get_one();
        last unless @$next_rec;
        foreach my $cooked_input (@$next_rec) {
          if (blessed ($cooked_input) and 
                       $cooked_input->isa('Data::Transform::Meta::SENDBACK')) {
            $self->[DRIVER_BOTH]->put([$cooked_input->{data}]);
            $poe_kernel->select_resume_write($self->[HANDLE_OUTPUT]);
            next;
          }
          $poe_kernel->call(
            $poe_kernel->get_active_session(),
            $self->[EVENT_INPUT],
            $cooked_input, $self->[UNIQUE_ID]
          );
        }
      }
    }
  }

  # Otherwise use the old behavior.
  else {
    if (defined $buf) {
      foreach my $cooked_input (@{$self->[FILTER_INPUT]->get($buf)}) {
        $poe_kernel->call(
          $poe_kernel->get_active_session(),
          $self->[EVENT_INPUT],
          $cooked_input, $self->[UNIQUE_ID]
        );
      }
    }
  }
}

# Set input and output filters.

sub set_filter {
  my ($self, $new_filter) = @_;
  my $buf = $self->[FILTER_INPUT]->get_pending();
  $self->[FILTER_INPUT] = $self->[FILTER_OUTPUT] = $new_filter;

  $self->_transfer_input_buffer($buf);
}

# Redefine input and/or output filters separately.
sub set_input_filter {
  my ($self, $new_filter) = @_;
  my $buf = $self->[FILTER_INPUT]->get_pending();
  $self->[FILTER_INPUT] = $new_filter;

  $self->_transfer_input_buffer($buf);
}

# No closures need to be redefined or anything.  All the previously
# put stuff has been serialized already.
sub set_output_filter {
  my ($self, $new_filter) = @_;
  $self->[FILTER_OUTPUT] = $new_filter;
}

# Get the current input filter; used for accessing the filter's custom
# methods, as in: $wheel->get_input_filter()->filter_method();
sub get_input_filter {
  my $self = shift;
  return $self->[FILTER_INPUT];
}

# Get the current input filter; used for accessing the filter's custom
# methods, as in: $wheel->get_input_filter()->filter_method();
sub get_output_filter {
  my $self = shift;
  return $self->[FILTER_OUTPUT];
}

# Set the high water mark.

sub set_high_mark {
  my ($self, $new_high_mark) = @_;

  unless (defined $self->[WATERMARK_WRITE_MARK_HIGH]) {
    carp "Ignoring high mark (must be initialized in constructor first)";
    return;
  }

  unless (defined $new_high_mark) {
    carp "New high mark is undefined.  Ignored";
    return;
  }

  unless ($new_high_mark > $self->[WATERMARK_WRITE_MARK_LOW]) {
    carp "New high mark would not be greater than low mark.  Ignored";
    return;
  }

  $self->[WATERMARK_WRITE_MARK_HIGH] = $new_high_mark;
  $self->_define_write_state();
}

sub set_low_mark {
  my ($self, $new_low_mark) = @_;

  unless (defined $self->[WATERMARK_WRITE_MARK_LOW]) {
    carp "Ignoring low mark (must be initialized in constructor first)";
    return;
  }

  unless (defined $new_low_mark) {
    carp "New low mark is undefined.  Ignored";
    return;
  }

  unless ($new_low_mark > 0) {
    carp "New low mark would be less than one.  Ignored";
    return;
  }

  unless ($new_low_mark < $self->[WATERMARK_WRITE_MARK_HIGH]) {
    carp "New low mark would not be less than high high mark.  Ignored";
    return;
  }

  $self->[WATERMARK_WRITE_MARK_LOW] = $new_low_mark;
  $self->_define_write_state();
}

# Return driver statistics.
sub get_driver_out_octets {
  $_[0]->[DRIVER_BUFFERED_OUT_OCTETS];
}

sub get_driver_out_messages {
  $_[0]->[DRIVER_BOTH]->get_out_messages_buffered();
}

# Get the wheel's ID.
sub ID {
  return $_[0]->[UNIQUE_ID];
}

# Pause the wheel's input watcher.
sub pause_input {
  my $self = shift;
  return unless defined $self->[HANDLE_INPUT];
  $poe_kernel->select_pause_read( $self->[HANDLE_INPUT] );
}

# Resume the wheel's input watcher.
sub resume_input {
  my $self = shift;
  return unless  defined $self->[HANDLE_INPUT];
  $poe_kernel->select_resume_read( $self->[HANDLE_INPUT] );
}

# Return the wheel's input handle
sub get_input_handle {
  my $self = shift;
  return $self->[HANDLE_INPUT];
}

# Return the wheel's output handle
sub get_output_handle {
  my $self = shift;
  return $self->[HANDLE_OUTPUT];
}

# Shutdown the socket for reading.
sub shutdown_input {
  my $self = shift;
  return unless defined $self->[HANDLE_INPUT];
  eval { local $^W = 0; shutdown($self->[HANDLE_INPUT], 0) };
  $poe_kernel->select_read($self->[HANDLE_INPUT], undef);
}

# Shutdown the socket for writing.
sub shutdown_output {
  my $self = shift;
  return unless defined $self->[HANDLE_OUTPUT];
  eval { local $^W=0; shutdown($self->[HANDLE_OUTPUT], 1) };
  $poe_kernel->select_write($self->[HANDLE_OUTPUT], undef);
}

# Flush the output handle
sub flush {
  my $self = shift;
  return unless defined $self->[HANDLE_OUTPUT];
  $poe_kernel->call($poe_kernel->get_active_session(),
        $self->[STATE_WRITE], $self->[HANDLE_OUTPUT]);
}

1;
