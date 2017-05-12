package BPM::Engine::Store::ResultBase::ProcessTransition;
BEGIN {
    $BPM::Engine::Store::ResultBase::ProcessTransition::VERSION   = '0.01';
    $BPM::Engine::Store::ResultBase::ProcessTransition::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;

with 'BPM::Engine::Store::ResultRole::TransitionCondition';

has to_activity => (
    does => "Class::Workflow::State",
    is   => "rw",
    required => 0,
    );

sub apply {
    my ($self, $instance, @args) = @_;

    my ($set_instance_attrs, @rv) = $self->_apply_body($instance, @args);
    $set_instance_attrs ||= {};

    my $new_instance = $self->derive_and_accept_instance($instance, {
            activity => ( $self->to_activity || die "$self has no 'to_activity'" ),
            %{$set_instance_attrs},
            },
        @args,
        );
    
    return wantarray ? ($new_instance, @rv) : $new_instance;
    }

sub _apply_body {
    my ($self, $instance, @args) = @_;
    
    return {}, (); # no fields, no additional values
    }

sub derive_and_accept_instance {
    my ($self, $proto_instance, $attrs, @args) = @_;

    my $activity = delete $attrs->{activity} 
        or die "You must specify the next activity of the instance";

    my $from_activity = $self->from_activity;    
    if($from_activity->split_type ne 'NONE') {
        # set transition 'taken' if coming from a split
        my $split = $proto_instance->split
            or die("No join found for split " . $from_activity->activity_uid);
        $split->set_transition($self->id, 'taken');
        }
        
    # Tokens placed on downstream edges keep the Tokenset of the firing Token. 
    # Tokens placed on upstream edges on the other hand will each be created in
    # the context of a new Tokenset.
    if($self->is_back_edge) { # upstream (start new cycle loop)
        $attrs->{tokenset} = $proto_instance->id;
        }
    else {
        $attrs->{tokenset} = $proto_instance->parent_token_id;
        }
    
    return $activity->new_instance({
        process_instance_id => $proto_instance->process_instance_id,
        prev                => $proto_instance->id,
        transition_id       => $self->id,
        %$attrs,
        });
    }


no Moose::Role;

1;
__END__