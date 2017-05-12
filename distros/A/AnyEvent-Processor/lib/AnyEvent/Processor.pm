package AnyEvent::Processor;
#ABSTRACT: Base class to define an event-driven (AnyEvent) task that could periodically be interrupted by a watcher
$AnyEvent::Processor::VERSION = '0.006';
use Moose;
use Modern::Perl;
use AnyEvent;
use Glib;
use AnyEvent::Processor::Watcher;

with 'AnyEvent::Processor::WatchableTask';


has verbose => ( is => 'rw', isa => 'Int' );

has watcher => ( 
    is => 'rw', 
    isa => 'AnyEvent::Processor::Watcher',
);

has count => ( is => 'rw', isa => 'Int', default => 0 );

has blocking => ( is => 'rw', isa => 'Bool', default => 0 );


sub run {
    my $self = shift;
    if ( $self->blocking ) {
        $self->run_blocking();
    }
    else {
        $self->run_task();
    }
}


sub run_blocking {
    my $self = shift;
    while ( $self->process() ) {
        ;
    }
}


sub run_task {
    my $self = shift;

    $self->start_process();

    if ( $self->verbose ) {
        $self->watcher(
            AnyEvent::Processor::Watcher->new( delay => 1, action => $self )
        ) unless $self->watcher;
        $self->watcher->start();
    }

    my $end_run = AnyEvent->condvar;
    my $idle = AnyEvent->idle( cb => sub {
        unless ( $self->process() ) {
            $self->end_process();
            $self->watcher->stop() if $self->watcher;
            $end_run->send;
        }
    });
    $end_run->recv;
}


sub start_process { }


sub start_message {
    say "Start process";
}


sub process {
    my $self = shift;
    $self->count( $self->count + 1 );
    return 1;
}


sub process_message {
    my $self = shift;
    say sprintf("  %#6d", $self->count);    
}


sub end_process { return 0; }


sub end_message {
    my $self = shift; 
    say "Number of items processed: ", $self->count;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Processor - Base class to define an event-driven (AnyEvent) task that could periodically be interrupted by a watcher

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  package FridgeMonitoring;
  
  use Moose;
  extends 'AnyEvent::Processor';
  use TemperatureSensor;
  
  has sensors => (is => 'rw', isa => 'ArrayRef[TemperatureSensor]');
  has min => (is => 'rw', isa => 'Int', default => '10');
  has max => (is => 'rw', isa => 'Int', default => '20');
  
  
  sub process {
      my $self = shift;
  
      my @failed;
      for my $sensor ( @{$self->sensors} ) {
          next if $self->sensor->temperature >= $self->min &&
                  $self->sensor->temperature <= $self->max;
          push @failed, $sensor;
      }
      if ( @failed ) {
          # Send an email to someone with the list of failed fridges
      }
  }
  
  sub process_message {
      my $self = shift;
      say "[", $self->count, "] Fridges testing";
  }

package Main;

use FridgeMonitoring;

my $processor = FridgeMonitoring->new(
    sensors => # Get a list of fridge sensors from somewhere
    min => 0,
    max => 40,
);
$processor->run();

=head1 DESCRIPTION

A processor task based on this class process anything that can be divided into
processing clusters. Each cluster is processed one by one by calling the
process() method. A count is incremented at the end of each cluster. By
default, a L<AnyEvent::Processor::Watcher> is associated with the class,
interrupting the processing each second for calling C<process_message>. 

=head1 ATTRIBUTES

=head2 verbose

Verbose mode. In this mode an AnyEvent::Processor::Watcher is automatically
created, with a 1s timeout, and action directly sent to this class. You can
create your own watcher subclassing AnyEvent::Processor::Watcher.

=head2 watcher

An AnyEvent::Processor::Watcher.

=head2 count

Number of items which have been processed.

=head2 blocking

Is it a blocking task (not a task). False by default.

=head1 METHODS

=head2 run

Run the process.

=head2 start_process

Something to do at beginning of the process.

=head2 start_message

Something to say about the process. Called by default watcher when verbose mode
is enabled. By default, just send to STDOUT 'Start process...'. Your class can
display another message, or do something else, like sending an email, or a
notification to a monitoring system like Nagios.

=head2 process

Process something and increment L<count>. This method has to be surclassed by
you class if you want to do someting else than incrementing the C<count>
attribute.

=head2 process_message

Say something about the process. Called by default watcher (verbose mode) each
1s. By default, just display the C<count> value. Your processor can display
something else than just the number of processing clusters already processed.
If your processor monitor the temperature of your fridge, you can display it...

=head2 end_process

Do something at the end of the process.

=head2 end_message

Say something at the end of the process. Called by default watcher. 

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent::Processor::Converion

=item *

L<AnyEvent::Processor::Watcher

=back

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
