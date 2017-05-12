package BPM::Engine::Store::Result::ActivityInstanceSplit;
BEGIN {
    $BPM::Engine::Store::Result::ActivityInstanceSplit::VERSION   = '0.01';
    $BPM::Engine::Store::Result::ActivityInstanceSplit::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/InflateColumn::Serializer Core /);
__PACKAGE__->table('wfe_activity_instance_join');
__PACKAGE__->add_columns(
    split_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 },
        size              => 11,
        },
    token_id => {
        data_type         => 'INT',
        size              => 11,
        is_foreign_key    => 1,
        extras            => { unsigned => 1 },
        },
    # whether the join has fired
    has_fired => {
        data_type         => 'BOOLEAN', # synonym for TINYINT(1)
        default_value     => 0,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },
    # the number of times the join has fired since the workflow started
    fired_count => {
        data_type         => 'INT',
        default_value     => 0,
        is_nullable       => 0,        
        size              => 6,
        extras            => { unsigned => 1 },
        },
    states => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },    
    );

__PACKAGE__->set_primary_key(qw/ split_id /);

__PACKAGE__->belongs_to(
    activity_instance => 'BPM::Engine::Store::Result::ActivityInstance', 'token_id'
    );

sub set_transition {
    my ($self, $transition_id, $state) = @_;
    
    die("Invalid split state '$state'") unless $state =~ /^(taken|blocked|joined)$/;
    my $states = $self->states || {};
    if($states->{$transition_id} && $state ne 'joined') {
        die("Transition state '$state' already set in Join as '" . 
            $states->{$transition_id} . "'"
            );
        }
    elsif(!$states->{$transition_id} && $state eq 'joined') {
        die("State '$state' not previously taken for transition '$transition_id'");
        }
    
    $states->{$transition_id} = $state || 'taken';
    $self->states($states);
    $self->update->discard_changes();
    }

sub should_fire {
    my ($self, $transition, $no_update) = @_;

    if($self->activity_instance->activity->id != $transition->from_activity->id) {
        die("Illegal transition for JoinActivity '" .
            $self->activity_instance->activity->activity_uid .
            "' doesn't match transition " . $transition->transition_uid .
            " activity '" . $transition->from_activity->activity_uid . "'");
        }
    
    $self->set_transition($transition->id, 'joined') unless $no_update;
  $self->discard_changes();
    
    my $states = $self->states;
    die("Transition " . $transition->transition_uid . " not taken") 
        unless $states->{$transition->id};    
    my @followed = grep { $states->{$_} eq 'joined' } keys %{$states};

    return 0 if scalar @followed != scalar keys %{$self->states};
    return 1;
    }

1;
__END__