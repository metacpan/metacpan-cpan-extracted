package BPM::Engine::Store::ResultRole::WithAssignments;
BEGIN {
    $BPM::Engine::Store::ResultRole::WithAssignments::VERSION   = '0.01';
    $BPM::Engine::Store::ResultRole::WithAssignments::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;

sub start_assignments {
    my $self = shift;
    my $assignments = $self->assignments || [];
    return grep { !$_->{AssignTime} || $_->{AssignTime} eq 'Start' } 
        @$assignments;
    }

sub end_assignments {
    my $self = shift;
    my $assignments = $self->assignments || [];
    return grep { $_->{AssignTime} eq 'End' } 
        @$assignments;
    }

no Moose::Role;

1;
__END__

# ABSTRACT: Role for Process, Transition and Activity