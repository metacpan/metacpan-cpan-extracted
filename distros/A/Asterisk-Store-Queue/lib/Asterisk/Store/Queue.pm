package Asterisk::Store::Queue;

use 5.008008;
use strict;
use warnings;
use attributes;
use Log::Log4perl qw( get_logger :levels );


require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Asterisk::Store::Queue ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

# global varibles
use vars qw( @global_entries $connection );

# logger setup
my $root_logger = get_logger("Asterisk"); 
my $base_logger = get_logger("Asterisk::Store::Queue");
$base_logger->level($WARN);
$root_logger->level($ERROR);
my $layout = Log::Log4perl::Layout::PatternLayout->new(
	"%d{ISO8601} %p %c %F:%-4L -- %m%n"
);
my $file_appender = Log::Log4perl::Appender->new(
	"Log::Dispatch::File",
	filename => "log/queue.log",
	mode => "append",
);
my $screen_appender = Log::Log4perl::Appender->new(
	"Log::Dispatch::Screen",
);
$screen_appender->threshold($ERROR);
$file_appender->layout($layout);
$screen_appender->layout($layout);
$base_logger->add_appender($file_appender);
$root_logger->add_appender($screen_appender);


=head1 NAME

Asterisk::Store::Queue - Class for Asterisk queue objects

=head1 SYNOPSIS

  use Asterisk::Store::Queue;

  my $queueobj =  Asterisk::Store::Queue->new(
    queue            => 'mainqueue',
    max              => 0,
    calls            => 0,
    abandoned        => 0,
    holdtime         => 0,
    completed        => 0,
    servicelevel     => 0,
    servicelevelperf => 0,
    weight           => 0,
  );

  ...

=head1 DESCRIPTION

  This module is used to store queue objects such as those returned
  from the Asterisk Manager Interface API.

=cut

# constructor method
sub new {
        my $invoker = shift;
        my $class = ref($invoker) || $invoker;
        my $self = {
              # attributes go here
              queue            => 'mainqueue',
              max              => 0,
              calls            => 0,
              abandoned        => 0,
              holdtime         => 0,
              completed        => 0,
              servicelevel     => 0,
              servicelevelperf => 0,
              weight           => 0,
              members          => [], # array of Queue::Member objects
              DEBUG => 0,
              @_, # override attributes
        };
        bless $self, $class;
	if ($self->{'DEBUG'}) {
		$base_logger->level($DEBUG);
	};
	$base_logger->debug("creating Asterisk::Store::Queue object");
        return $self;
}

=head1 ATTRIBUTES

  Base attrubutes, can be extended

=head2 queue

  Queue name

=cut
sub queue {
        my $self = shift;
        if (@_) {
	      $self->{'queue'}= shift;
        }
        return $self->{'queue'};
}

=head2 max

  Max number of calls

=cut
sub max {
        my $self = shift;
        if (@_) {
	      $self->{'max'}= shift;
        }
        return $self->{'max'};
}

=head2 calls

  Number of current calls waiting in queue

=cut
sub calls {
        my $self = shift;
        if (@_) {
	      $self->{'calls'}= shift;
        }
        return $self->{'calls'};
}

=head2 abandoned

  Number of abandoed calls in queue

=cut
sub abandoned {
        my $self = shift;
        if (@_) {
	      $self->{'abandoned'}= shift;
        }
        return $self->{'abandoned'};
}

=head2 holdtime

  Current hold time for queue

=cut
sub holdtime {
        my $self = shift;
        if (@_) {
	      $self->{'holdtime'}= shift;
        }
        return $self->{'holdtime'};
}

=head2 completed

  Number of calls that have been completed in the queue

=cut
sub completed {
        my $self = shift;
        if (@_) {
	      $self->{'completed'}= shift;
        }
        return $self->{'completed'};
}

=head2 servicelevel

  Current service level

=cut
sub servicelevel {
        my $self = shift;
        if (@_) {
	      $self->{'servicelevel'}= shift;
        }
        return $self->{'servicelevel'};
}

=head2 servicelevelperf

  Service level performance

=cut
sub servicelevelperf {
        my $self = shift;
        if (@_) {
	      $self->{'servicelevelperf'}= shift;
        }
        return $self->{'servicelevelperf'};
}

=head2 weight

  Queue weight

=cut
sub weight {
        my $self = shift;
        if (@_) {
	      $self->{'weight'}= shift;
        }
        return $self->{'weight'};
}

=head2 members

  Queue members -- An array of Asterisk::Store::Queue::Member objects

=cut
sub members {
        my $self = shift;
        if (@_) {
	      $self->{'members'}= shift;
        }
        return $self->{'members'};
}

=head2 DEBUG *bool*

  Enable debugging by setting bool to true.

=cut

sub DEBUG {
        my $self = shift;
        if (@_) {
	      $self->{'DEBUG'}= shift;
        }
	if ($self->{'DEBUG'}) {
		$base_logger->level($DEBUG);
	};
        return $self->{'DEBUG'};
}

=head1 PUBLIC METHODS

  These are the publicly accesable methods

=cut

=head2 add_member()

  Add a new member object to the queue. Must be a Asterisk::Queue::Member object
  
  usage:
    $queueobj->add_member($memberobj)

=cut
sub add_member() {
	my $self = shift;
	my $internalobj = shift;
	if ( UNIVERSAL::isa $internalobj, 'Asterisk::Store::Queue::Member' ) {
		push @{$self->{'members'}}, $internalobj;
	} else {
		$base_logger->warn("add_member failed: not a Asterisk::Store::Queue::Member object");
		return undef;
	}
}


=head1 PRIVATE METHODS

  These methods should not be accessed directly.

=cut


=head1 SEE ALSO

To be used with:
  L<Asterisk::Store::Queue::Member>
  L<Asterisk::Manager>

=head1 AUTHOR

Derek Carter, E<lt>goozbach@neverblock.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Derek Carter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
