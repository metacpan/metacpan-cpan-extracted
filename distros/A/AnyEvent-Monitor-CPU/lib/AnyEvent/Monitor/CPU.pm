package AnyEvent::Monitor::CPU;
our $VERSION = '0.3';



use common::sense;
use AnyEvent;
use Proc::CPUUsage;
use Carp qw( croak );
use parent qw( Exporter );

@AnyEvent::Monitor::CPU::EXPORT_OK = ('monitor_cpu');

## Shortcut, optional import
sub monitor_cpu { return __PACKAGE__->new(@_) }


sub new {
  my $class = shift;
  my %args = @_ == 1 ? %{$_[0]} : @_;

  my $self = bless {
    cb => delete $args{cb},

    interval => delete $args{interval} || .25,

    high         => delete $args{high}         || .95,
    low          => delete $args{low}          || .80,
    high_samples => delete $args{high_samples} || 2,
    low_samples  => delete $args{low_samples}  || 2,
    cur_high_samples => 0,
    cur_low_samples  => 0,

    cpu   => Proc::CPUUsage->new,
    usage => undef,
    state => 1,
  }, $class;

  croak("Required parameter 'cb' not found, ") unless $self->{cb};
  croak("Parameter 'cb' must be a coderef, ") unless ref $self->{cb} eq 'CODE';

  $self->start;

  return $self;
}

sub start {
  my $self = shift;

  $self->{timer} = AnyEvent->timer(
    after    => $self->{interval},
    interval => $self->{interval},
    cb       => sub { $self->_check_cpu },
  );

  $self->{usage} = $self->{cpu}->usage;
  $self->reset_stats;  

  return;
}

sub stop       { delete $_[0]->{timer} }
sub is_running { $_[0]->{timer} }

sub usage   { return $_[0]->{usage} }
sub is_low  { return $_[0]->{state} == 1 }
sub is_high { return $_[0]->{state} == 0 }

sub reset_stats {
  my ($self) = @_;
  
  $self->{usage_sum} = 0;
  $self->{usage_count} = 0;
}

sub stats {
  my ($self) = @_;
  my %stats;
  
  my ($count, $sum);
  if ($count = $self->{usage_count}) {
    $sum = $self->{usage_sum};
    $stats{usage_avg} = $sum/$count;
  }
  $stats{usage_count} = $count;
  $stats{usage_sum}   = $sum;
  $stats{usage}       = $self->{usage};

  return \%stats;
}

sub _check_cpu {
  my $self = $_[0];
  my $chs  = $self->{current_high_samples};
  my $cls  = $self->{current_low_samples};

  my $usage = $self->{usage} = $self->{cpu}->usage;
  if    ($usage > $self->{high}) { $chs++; $cls = 0 }
  elsif ($usage < $self->{low})  { $cls++; $chs = 0 }
  else {
    $chs-- if $chs;
    $cls-- if $cls;
  }
  $self->{usage_sum} += $usage;
  $self->{usage_count}++;

  my $hs      = $self->{high_samples};
  my $ls      = $self->{low_samples};
  my $state   = $self->{state};
  my $trigger = 0;
  if ($chs >= $hs) {
    $chs = $hs;
    if ($state) {
      $state   = 0;
      $trigger = 1;
    }
  }
  elsif ($cls >= $ls) {
    $cls = $ls;
    if (!$state) {
      $state   = 1;
      $trigger = 1;
    }
  }

  $self->{state}                = $state;
  $self->{current_high_samples} = $chs;
  $self->{current_low_samples}  = $cls;

  $self->{cb}->($self, $state) if $trigger;
}


1;

__END__

=encoding utf8

=head1 NAME

AnyEvent::Monitor::CPU - monitors your process CPU usage, with high/low watermark triggers


=head1 VERSION

version 0.3

=head1 SYNOPSIS

    use AnyEvent::Monitor::CPU qw( monitor_cpu );

    my $monitor = monitor_cpu cb => sub {
        my ($self, $on_off_flag) = @_;

        # look at $on_off_flag
        #   * 1: below the low watermak - you can increase your CPU usage
        #   * 0: above the high watermark - reduce your CPU usage;
      }
    ;

    ## Or...

    use AnyEvent::Monitor::CPU;

    my $monitor = AnyEvent::Monitor::CPU->new(
      cb => sub { ... }
    );

    ## other goodies
    my $last_measured_usage = $monitor->usage;
    my $have_spare_cpu = $monitor->is_low;
    my $we_are_overloaded = $monitor->is_high;
    
    ## stats
    use Data::Dump qw(pp);
    my $stats = $monitor->stats;
    print pp($stats);
    # {
    #   usage_count => 5,
    #   usage_sum   => 3.344552,
    #   usage_avg   => 0.668910,
    #   usage       => 0.540231,
    # }
    
    $monitor->reset_stats;
    print pp($monitor->stats);
    # {
    #   usage_count => 0,
    #   usage_sum   => 0,
    #   usage       => 0.481203,
    # }
    
    ## monitor stop/start control
    $monitor->stop;
    $monitor->start;
    $monitor->is_running;


=head1 DESCRIPTION

This module gives you a CPU monitor with high/low threseholds and
triggers.

On a regular basis, it will check the CPU usage of the current process.
If the usage is above your designated upper limit for more than a number
of samples, it will trigger the provided callback.

If the CPU usage lowers below the provided lower limit for more than a
number of samples, it will trigger the callback again.

See the constructor L</"new()"> documentation for all the parameters
that you can set, and their default values.

For each transition (above upper limit, below lower limit), the callback
will be called only once.

All load values are between 0 and 1, between a idle processor (0) and a
full blown fried eggs machine (1).

You can inspect the current state of the monitor. You can check the last
usage that was sampled, and the average usage over the last samples.

An API is also provided to stop and restart the monitor.


=head1 PERFORMANCE

With the default parameters, the overhead of the CPU monitor is less
than 0.05%, as measured on both of my development machines (a MacBook
laptop with a 2.16Ghz Intel Core Duo, and a PC with a 2.66Ghz Intel
Quad Core).

Please note that if you run your code under L<Devel::Cover|Devel::Cover>
the average loads will most likelly be outside the limits.


=head1 METHODS

=head2 new()

    $cpu = AnyEvent::Monitor::CPU->new( cb => sub {}, ... );
    $cpu = AnyEvent::Monitor::CPU->new({ cb => sub {}, ... });

Creates a new L<AnyEvent::Monitor::CPU|AnyEvent::Monitor::CPU> object
and start the polling process.

The following parameters are accepted:

=over 4

=item cb

    cb => sub {
      my ($monitor, $high_low_flag) = @_;
      
      say $high_low_flag? "I'm bored..." : "I'm high as a kite!";
    },
    
The callback to be used when the CPU usage rises above or lowers below
the defined thresholds.

This parameter is B<required> and it should be a coderef.

The callback will be called with two parameters:

=over 4

=item $monitor

The monitor object.

=item $high_low_flag

Flag with the current state of the CPU usage. The possible values are:

=over 4

=item 0

The CPU is over the defined high limit.

=item 1

The CPU is under the defined low limit.

=back

Your callback should tune the application to increase or decrease the
CPU usage based on the C<$high_low_flag> value.

=back


=item interval

    interval => .1, ## sample 10 times per second

The sample interval. Use fractional values for sub-second intervals.

The default value is C<.25>, so it will sample the CPU usage 4 times
per second.


=item high

    high => .40,  ## set the upper limit to 40%

Defines the upper limit for the CPU usage.

The default value is C<.95>.


=item low

    low => .20,  ## set the lower limit to 20%

Defines the lower limit for the CPU usage.

The default value is C<.80>.


=item high_samples

    ## Only trigger the cb after 4 consecutive samples above the
    ## high limit
    high_samples => 4,

Set the number of samples above the high limit that we require to
trigger the callback.

The default value is C<2>.


=item low_samples

    ## Only trigger the cb after 2 consecutive samples under the
    ## low limit
    low_samples => 4,

Set the number of samples under the low limit that we require to
trigger the callback.

The default value is C<2>.


=back


=head2 monitor_cpu()

    my $monitor = monitor_cpu cb => sub {}, interval => .1;

A shortcut to C<< AnyEvent::Monitor::CPU->new(@args) >>. All parameters
are passed along to the L</"new()"> constructor.

The C<monitor_cpu()> function is not imported by default. You must ask for it.


=head2 usage()

    $usage = $monitor->usage()

Returns the last sampled CPU usage.

The value returned is between 0 and 1.


=head2 is_high()

    if ($monitor->is_high()) {
      say "Your eggs will be ready in a minute";
    }

Returns true if the CPU usage is over the defined limits.


=head2 is_low()

    if ($monitor->is_low()) {
      say "Its chilly in here, wanna generate some heat?";
    }

Returns true if the CPU usage is below the defined limits.


=head2 stats()

    my $stats = $monitor->stats;
    my $count = $stats->{usage_count};
    say "Average usage was $stats->{usage_avg} over the last $count samples"
      if $count;

Returns a hashref with statistics. The following keys are available:

=over 4

=item usage

The last usage sample taken. Its the same as C<< $monitor->usage >>.

=item usage_count

The number of samples taken since the last L<\"reset_stats()">.

=item usage_sum

The sum of the samples taken since the last L<\"reset_stats()">.

=item usage_avg

The average usage since the last L<\"reset_stats()">.

This value is only available if C<usage_count> is non-zero.

=back


=head2 reset_stats()

    $monitor->reset_stats();

Clears the stats.


=head2 stop()

    $monitor->stop();

Stops the polling process for the CPU monitor.


=head2 start()

    $monitor->start();

Starts the polling process for the CPU monitor.


=head2 is_running()

    if ($monitor->is_running()) {
      say "Big brother is watching, play it cool";
    }
    else {
      say "Bring on the bacon and eggs, lets make breakfast!";
    }

Returns true if the monitor is polling the CPU usage.


=head1 SEE ALSO

L<Proc::CPUUsage|Proc::CPUUsage>.


=head1 AUTHOR

Pedro Melo, C<< <melo at cpan.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Pedro Melo.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut