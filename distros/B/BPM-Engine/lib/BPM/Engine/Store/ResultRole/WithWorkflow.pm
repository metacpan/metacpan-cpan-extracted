package BPM::Engine::Store::ResultRole::WithWorkflow;
BEGIN {
    $BPM::Engine::Store::ResultRole::WithWorkflow::VERSION   = '0.01';
    $BPM::Engine::Store::ResultRole::WithWorkflow::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;

requires 'get_workflow';

has workflow => (
    does    => 'Class::Workflow',
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->get_workflow();
        },
    );

has error => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
    default  => sub { '' },
    );

sub apply_transition {
    my ($self, $transition, @args) = @_;

    unless(ref($transition)) {
        my $transitionid = $transition;
        my $state = $self->workflow_instance->state;
        $state->_reindex_hash;
        $transition = $state->get_transition($transition)
            or die "There's no '$transitionid' transition from " . $state->name;
        }

    $self->_workflow_txn(sub {
        my ($self, $instance) = @_;
        $transition->apply($instance, @args);
        });
    }

sub _workflow_txn {
    my ($self, $sub) = @_;

    $self->result_source->schema->txn_do(sub {
        # pass the current workflow instance to the closure, and if
        # the closure returns a valid instance, store it in the object
        my $new_instance = eval { $self->$sub($self->workflow_instance) };
        
        if (defined $new_instance) {
            $self->workflow_instance($new_instance);
            $self->update;
            }
        elsif ($@) { 
            die $@;
            }
        else { 
            die "$sub did not return a new workflow instance"; 
            }
        });
    }

sub clone {
    my ( $self, %fields ) = @_;
    $self->copy({%fields});
    }

sub state { ## no critic (ProhibitBuiltinHomonyms)
    my $self = shift;
    return $self->workflow_instance->state->name;
    }

sub workflow_instance {
    my ($self, $newinst) = @_;
    if($newinst) {
        my $newid = ref($newinst) ? $newinst->id : $newinst;
        $self->workflow_instance_id($newid);
        }
    return $self->state_events->find({ event_id => $self->workflow_instance_id });
    }


no Moose::Role;

# ABSTRACT: Workflow role for ResultBase::ProcessInstance and ResultBase::ActivityInstance

1;
__END__
