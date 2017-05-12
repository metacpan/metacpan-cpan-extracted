package BPM::Engine::Store::Result::ProcessInstance;
BEGIN {
    $BPM::Engine::Store::Result::ProcessInstance::VERSION   = '0.01';
    $BPM::Engine::Store::Result::ProcessInstance::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
extends qw/BPM::Engine::Store::Result/;
with    qw/BPM::Engine::Store::ResultBase::ProcessInstance
           BPM::Engine::Store::ResultRole::WithAttributes/;

use Silly::Werder;

my $WORDGEN = Silly::Werder->new();

__PACKAGE__->load_components(qw/TimeStamp DynamicDefault/);
__PACKAGE__->table('wfe_process_instance');
__PACKAGE__->add_columns(
    instance_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },
    process_id => {
        data_type         => 'CHAR',
        size              => 36,
        is_nullable       => 0,
        is_foreign_key    => 1,
        },    
    parent_ai_id => {     # parent blockactivity
        data_type         => 'INT',
        is_nullable       => 1,
        },
    instance_name => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        dynamic_default_on_create => sub { $WORDGEN->get_werd() },
        },
    workflow_instance_id => { # state machine
        data_type         => 'INT',
        is_nullable       => 1,
        },
    created => {
        data_type         => 'DATETIME',
        is_nullable       => 0,
        set_on_create     => 1,
        timezone          => 'UTC',
        },
    completed => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        timezone          => 'UTC',
        },
    );

__PACKAGE__->set_primary_key(qw/ instance_id /);

__PACKAGE__->belongs_to(
    process => 'BPM::Engine::Store::Result::Process','process_id'
    );

__PACKAGE__->has_many(
    attributes => 'BPM::Engine::Store::Result::ProcessInstanceAttribute',
    { 'foreign.process_instance_id' => 'self.instance_id' }
    );

__PACKAGE__->has_many(
    activity_instances => 'BPM::Engine::Store::Result::ActivityInstance',
    { 'foreign.process_instance_id' => 'self.instance_id' }, { order_by => 'prev' }
    );

__PACKAGE__->belongs_to(
    parent_activity_instance => 'BPM::Engine::Store::Result::ActivityInstance',
    { 'foreign.token_id' => 'self.parent_ai_id' }
    );

__PACKAGE__->has_many(
    state_events => 'BPM::Engine::Store::Result::ProcessInstanceState',
    { 'foreign.process_instance_id' => 'self.instance_id' }
    );

__PACKAGE__->has_many(
    workitems => 'BPM::Engine::Store::Result::WorkItem',
    { 'foreign.process_instance_id' => 'self.instance_id' }
    );

sub insert {
    my ($self, @args) = @_;

    my $guard = $self->result_source->schema->txn_scope_guard;

    $self->next::method(@args);
    $self->discard_changes;

    my $rel = $self->create_related('state_events', {
        state => $self->workflow->get_state($self->workflow->initial_state),
        });
    $self->update({ workflow_instance_id => $rel->id });

    $guard->commit;

    return $self;
    }

sub TO_JSON {
    my $self = shift;
    my $fields = {
        map { $_ => $self->$_() } 
            qw/instance_id process_id instance_name created completed/
        };
    # $fields->{attributes} = [ map { $_->TO_JSON } $self->attributes_rs->all ];
    return $fields;
    }

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
__END__