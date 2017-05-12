package Asterisk::Store::Queue::Member;

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

# This allows declaration	use Asterisk::Store::Queue::Member ':all';
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
my $base_logger = get_logger("Asterisk::Store::Queue::Member");
$base_logger->level($WARN);
$root_logger->level($ERROR);
my $layout = Log::Log4perl::Layout::PatternLayout->new(
	"%d{ISO8601} %p %c %F:%-4L -- %m%n"
);
my $file_appender = Log::Log4perl::Appender->new(
	"Log::Dispatch::File",
	filename => "log/member.log",
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

Asterisk::Store::Queue::Member - Class for Asterisk queue member objects

=head1 SYNOPSIS

  use Asterisk::Store::Queue::Member;

  my $memberobj =  new Asterisk::Store::Queue::Member (
    queue      => 'mainqueue',
    location   => 'Local/42342@queueagents',
    membership => 'dynamic',
    penalty    => 0,
    callstaken => 0,
    paused     => 0,
    status     => 0,
    lastcall   => 0,
  }

  ...

=head1 DESCRIPTION

  This module is used to store queue member objects such as those returned
  from the Asterisk Manager Interface API.

=cut

# constructor method
sub new {
        my $invoker = shift;
        my $class = ref($invoker) || $invoker;
        my $self = {
              # attributes go here
              queue      => 'mainqueue',
              location   => 'Local/42342@queueagents',
              membership => 'dynamic',
              penalty    => 0,
              callstaken => 0,
              paused     => 0,
              status     => 0,
              lastcall   => 0,
              DEBUG => 0,
              @_, # override attributes
        };
        bless $self, $class;
	if ($self->{'DEBUG'}) {
		$base_logger->level($DEBUG);
	};
	$base_logger->debug("creating Asterisk::Store::Queue::Member object");
        return $self;
}

=head1 ATTRIBUTES

  Base attrubutes, can be extended

=head2 queue

  Which queue is this member a member of?

=cut
sub queue {
        my $self = shift;
        if (@_) {
	      $self->{'queue'}= shift;
        }
        return $self->{'queue'};
}

=head2 location

  Where is this agent (member) located?

=cut
sub location {
        my $self = shift;
        if (@_) {
	      $self->{'location'}= shift;
        }
        return $self->{'location'};
}

=head2 membership

  Type of membership (dynamic, etc...)

=cut
sub membership {
        my $self = shift;
        if (@_) {
	      $self->{'membership'}= shift;
        }
        return $self->{'membership'};
}

=head2 penalty

  Queue penalty assigned to member

=cut
sub penalty {
        my $self = shift;
        if (@_) {
	      $self->{'penalty'}= shift;
        }
        return $self->{'penalty'};
}

=head2 callstaken

  Number of calls that the member has handled

=cut
sub callstaken {
        my $self = shift;
        if (@_) {
	      $self->{'callstaken'}= shift;
        }
        return $self->{'callstaken'};
}

=head2 paused

  Member pause status *bool*

=cut
sub paused {
        my $self = shift;
        if (@_) {
	      $self->{'paused'}= shift;
        }
        return $self->{'paused'};
}

=head2 status

  Member status

=cut
sub status {
        my $self = shift;
        if (@_) {
	      $self->{'status'}= shift;
        }
        return $self->{'status'};
}

=head2 lastcall

  Last call information

=cut
sub lastcall {
        my $self = shift;
        if (@_) {
	      $self->{'lastcall'}= shift;
        }
        return $self->{'lastcall'};
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

=head1 PRIVATE METHODS

  These methods should not be accessed directly.

=cut


=head1 SEE ALSO

To be used with:
  L<Asterisk::Store::Queue>
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
