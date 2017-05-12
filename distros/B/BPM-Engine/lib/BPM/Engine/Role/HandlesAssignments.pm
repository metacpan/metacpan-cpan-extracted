package BPM::Engine::Role::HandlesAssignments;
BEGIN {
    $BPM::Engine::Role::HandlesAssignments::VERSION   = '0.01';
    $BPM::Engine::Role::HandlesAssignments::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;
use BPM::Engine::Util::ExpressionEvaluator;

requires qw/process_instance process/;

before 'start_process' => sub {
    my $self = shift;

    my @assignments = $self->process->start_assignments;
    return unless scalar @assignments;

    my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
        process          => $self->process,
        process_instance => $self->process_instance,
        );

    foreach my $ass (@assignments) {
        $evaluator->assign($ass->{Target}, $ass->{Expression});
        }
    };

before 'complete_process' => sub {
    my $self = shift;

    my @assignments = $self->process->end_assignments;
    return unless scalar @assignments;

    my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
        process          => $self->process,
        process_instance => $self->process_instance,
        );

    foreach my $ass (@assignments) {
        $evaluator->assign($ass->{Target}, $ass->{Expression});
        }
    };

before 'start_activity' => sub {
    my ($self, $activity, $instance) = @_;

    my @assignments = $activity->start_assignments;
    return unless scalar @assignments;

    my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
        activity          => $activity,
        activity_instance => $instance,
        process           => $self->process,
        process_instance  => $self->process_instance,
        );

    foreach my $ass (@assignments) {
        $evaluator->assign($ass->{Target}, $ass->{Expression});
        }
    };

before 'complete_activity' => sub {
    my ($self, $activity, $instance) = @_;

    my @assignments = $activity->end_assignments;
    return unless scalar @assignments;

    my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
        activity          => $activity,
        activity_instance => $instance,
        process           => $self->process,
        process_instance  => $self->process_instance,
        );

    foreach my $ass (@assignments) {
        $evaluator->assign($ass->{Target}, $ass->{Expression});
        }
    };

around '_execute_transition' => sub {
    my ($orig, $self, $transition, $instance) = @_;

    my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
        activity_instance => $instance,
        transition        => $transition,
        process           => $self->process,
        process_instance  => $self->process_instance,
        #args              => [@args],
        );

    foreach my $ass ($transition->start_assignments) {
        $evaluator->assign($ass->{Target}, $ass->{Expression});
        }

    my $res = $self->$orig($transition, $instance);

    foreach my $ass ($transition->end_assignments) {
        $evaluator->assign($ass->{Target}, $ass->{Expression});
        }

    return $res;
    };

no Moose::Role;

1;
__END__

=pod

=encoding utf-8

=head1 NAME

BPM::Engine::Role::HandlesAssignments - ProcessRunner role for processing Assignments

=head1 DESCRIPTION

This L<ProcessRunner> role executes Assignments at the start and end of
Processes, Activities and Transitions.

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
