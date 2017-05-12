package BPM::Engine::Store::Result::ActivityInstance;
BEGIN {
    $BPM::Engine::Store::Result::ActivityInstance::VERSION   = '0.01';
    $BPM::Engine::Store::Result::ActivityInstance::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
use DateTime;

BEGIN {
  extends qw/BPM::Engine::Store::Result/;
  with    qw/BPM::Engine::Store::ResultBase::ActivityInstance
             BPM::Engine::Store::ResultRole::ActivityInstanceJoin
             BPM::Engine::Store::ResultRole::WithAttributes/;
  }

__PACKAGE__->load_components(qw/InflateColumn::Serializer/);
__PACKAGE__->table('wfe_activity_instance'); #process_token
__PACKAGE__->add_columns(
    token_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 },
        size              => 11,
        },
    parent_token_id => {
        data_type         => 'INT',
        is_nullable       => 1,
        extras            => { unsigned => 1 },
        size              => 11,
        },
    process_instance_id => {
        data_type         => 'INT',
        extras            => { unsigned => 1 },
        is_foreign_key    => 1,        
        is_nullable       => 0,
        },
    activity_id => {      # process state
        data_type         => 'INT',
        is_foreign_key    => 1,        
        is_nullable       => 0,
        extras            => { unsigned => 1 },
        },
    transition_id => {    # the transition this instance is a result of
        data_type         => 'INT',
        is_foreign_key    => 1,        
        is_nullable       => 1,
        },
    prev => {             # the activity instance this instance was derived from
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 1,
        },
    workflow_instance_id => { # (internal) state machine
        data_type         => 'INT',
        extras            => { unsigned => 1 },
        is_foreign_key    => 1,
        is_nullable       => 1,
        size              => 11,
        },
    tokenset => {         # upstream split, of which this is a branch
                          # (only relevant to instances within a cycle)
        data_type         => 'INT',
        is_nullable       => 1,
        extras            => { unsigned => 1 },
        size              => 11,
        },    
    inputset => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },
    taskdata => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },    
    taskresult => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },    
    created => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        set_on_create     => 1,
        timezone          => 'UTC',
        },
    deferred => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        timezone          => 'UTC',
        },
    completed => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        timezone          => 'UTC',
        },    
    );

__PACKAGE__->set_primary_key(qw/ token_id /);

__PACKAGE__->belongs_to(
    process_instance => 'BPM::Engine::Store::Result::ProcessInstance',
    'process_instance_id'
    );

# state
__PACKAGE__->belongs_to(
    activity => 'BPM::Engine::Store::Result::Activity', 'activity_id' 
    );

# the transition this instance is a result of
__PACKAGE__->belongs_to(
    transition => 'BPM::Engine::Store::Result::Transition', 'transition_id'
    );

# history, the instance this instance was derived from
__PACKAGE__->belongs_to(
    prev => __PACKAGE__
    );

__PACKAGE__->has_many(
    next => __PACKAGE__,   { 'foreign.prev' => 'self.token_id' }
    );

__PACKAGE__->belongs_to(
    parent => __PACKAGE__, { 'foreign.token_id' => 'self.parent_token_id' });

__PACKAGE__->has_many(
    children => __PACKAGE__, { 'foreign.parent_token_id' => 'self.token_id' });

__PACKAGE__->has_many(
    state_events => 'BPM::Engine::Store::Result::ActivityInstanceState',
    { 'foreign.token_id' => 'self.token_id' }, { cascade_delete => 1 }
    );

__PACKAGE__->might_have(
    'split' => 'BPM::Engine::Store::Result::ActivityInstanceSplit', 
            { 'foreign.token_id' => 'self.token_id' }
    );

__PACKAGE__->has_many(
    attributes => 'BPM::Engine::Store::Result::ActivityInstanceAttribute',
                { 'foreign.activity_instance_id' => 'self.token_id' }
    );

__PACKAGE__->has_many(
    workitems => 'BPM::Engine::Store::Result::WorkItem',
    { 'foreign.token_id' => 'self.token_id' }
    );

#__PACKAGE__->has_many(
#    data_objects => 'BPM::Engine::Store::Result::DataObjectInstance',
#                { 'foreign.token_id' => 'self.token_id' }
#    );

sub insert {
    my ($self, @args) = @_;
    
    my $guard = $self->result_source->schema->txn_scope_guard;
    
    $self->next::method(@args);
    $self->discard_changes;
    
    my $state = $self->create_related('state_events', {
        state => $self->workflow->get_state($self->workflow->initial_state),
        });    
    $self->update({ workflow_instance_id => $state->id });    
    
    $guard->commit;

    return $self;
    }

sub is_active {
    my $self = shift;
    return $self->completed || $self->deferred ? 0 : 1;
    }

sub is_deferred {
    my $self = shift;
    return $self->deferred ? 1 : 0;
    }

sub is_completed {
    my $self = shift;    
    return $self->completed ? 1 : 0;    
    }

sub TO_JSON {
    my ($self, $level) = @_;
    
    my %struct = map { $_ => $self->$_ } grep { $self->$_ }
        (qw/
            token_id parent_token_id process_instance_id activity_id
            transition_id workflow_instance_id tokenset 
             taskresult created deferred completed
             state
            /); # taskdata inputset # 
    
    #foreach my $rel(qw/workitems attributes prev next/) { #  activity
    #    $struct{$rel} = $self->$rel;
    #    }
    
    return \%struct;
    }

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
__END__