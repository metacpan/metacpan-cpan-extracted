package Bb::Collaborate::Ultra::Session::Log;
use warnings; use strict;
use Mouse;
use JSON;
extends 'Bb::Collaborate::Ultra::DAO';
use Mouse::Util::TypeConstraints;
use Bb::Collaborate::Ultra::Session::Log::Attendee;

=head1 NAME

Bb::Collaborate::Ultra::Session::Log

=head1 DESCRIPTION

Session logging class.

=head1 EXAMPLE

    my @sessions =  Bb::Collaborate::Ultra::Session->get($connection, {contextId => $context_id});
    for my $session (@sessions) {
	print "Session: ". $session->name . "\n";
	my @logs = $session->logs({expand => 'attendees' });

	for my $log (@logs) {
	    say "\tOpened: " .(scalar localtime $log->opened);
	    for my $attendee (@{$log->attendees}) {
		my $first_join;
		my $elapsed = 0;
		for my $attendance (@{$attendee->attendance}) {
		    my $joined = $attendance->joined;
		    $first_join = $joined
			if !$first_join || $first_join > $joined;
		    $elapsed += $attendance->left - $joined;
		}
		say sprintf("\tUser %s (%s) joined at %s, stayed %d minutes", $attendee->externalUserId, $attendee->displayName, (scalar localtime $first_join), $elapsed / 60);
	    }
	    say "\tClosed: " .(scalar localtime $log->closed);
	}
    }

=head1 METHODS

This class supports the `get` method as described in L<https://xx-csa.bbcollab.com/documentation#Attendee-collection>.

=cut
    
coerce __PACKAGE__, from 'HashRef' => via {
    __PACKAGE__->new( $_ )
};
 
sub _thaw {
    my $self = shift;
    my $data = shift;
    my $thawed = $self->SUPER::_thaw($data, @_);
    my $attendees = $data->{attendees};
    $thawed->{attendees} = [ map { Bb::Collaborate::Ultra::Session::Log::Attendee->_thaw($_) } (@$attendees) ]
	if $attendees;
    $thawed;
}

__PACKAGE__->resource('instances');
__PACKAGE__->load_schema(<DATA>);

__PACKAGE__->query_params(
    expand => 'Str', # 'attendees'
    );

subtype 'ArrayOfAttendees',
    as 'ArrayRef[Bb::Collaborate::Ultra::Session::Log::Attendee]';

coerce 'ArrayOfAttendees',
    from 'ArrayRef[HashRef]',
    via { [ map {Bb::Collaborate::Ultra::Session::Log::Attendee->new($_)} (@$_) ] };

has 'attendees' => (isa => 'ArrayOfAttendees', is => 'rw', coerce => 1);

=head2 get_attendees

Returns a list of attendees for this session instance;

   my @all_attendees;
   my @logs = $session->get_logs;
   for my $log (@logs) {
       push @all_attendees, $log->get_attendees;
   }

Note: Alternatively, the C<expand => 'attendees'> query parameter may be set in the C<get_logs>. This causes the server to eagerly populate the attendees in each session log.

   my @all_attendees;
   my @logs = $session->get_logs({expand => 'attendees' });
   for my $log (@logs) {
       push @all_attendees, @{ $log->attendees };
   }

This reduces the number of calls to the server, and is generally faster.

=cut

sub get_attendees {
    my $self = shift;
    my $query = shift || {};
    my %opt = @_;

    my $connection = $opt{connection} || $self->connection;
    my $path = $self->path.'/attendees';
    require Bb::Collaborate::Ultra::Session::Log::Attendee;
    my @attendees = Bb::Collaborate::Ultra::Session::Log::Attendee->get($connection => $query, path => $path, parent => $self);
    $self->{attendees} = \@attendees
	if $opt{cache};

    @attendees;
}

# **NOT DOCUMENTED** in https://xx-csa.bbcollab.com/documentation
# schema has been reversed engineered
1;
__DATA__
{
    "type" : "object",
    "id" : "SessionLog",
    "properties" : {
        "id" : {
            "type" : "string"
        },
        "opened" : {
            "type" : "string",
            "format" : "DATE_TIME"
        },
        "closed" : {
            "type" : "string",
            "format" : "DATE_TIME"
        }
    }
}
