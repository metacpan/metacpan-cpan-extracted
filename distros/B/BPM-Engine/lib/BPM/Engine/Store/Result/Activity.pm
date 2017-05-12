package BPM::Engine::Store::Result::Activity;
BEGIN {
    $BPM::Engine::Store::Result::Activity::VERSION   = '0.01';
    $BPM::Engine::Store::Result::Activity::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
extends qw/BPM::Engine::Store::Result/;
with    qw/BPM::Engine::Store::ResultBase::Activity
           BPM::Engine::Store::ResultRole::WithAssignments/;

__PACKAGE__->load_components(qw/ InflateColumn::Serializer /);
__PACKAGE__->table('wfd_activity');
__PACKAGE__->add_columns(
    activity_id => {
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
    activity_uid => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        },    
    activity_name => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    activity_type => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'Implementation',
        default_value     => 'Implementation',        
        extra             => { 
            list          => [qw/Implementation Route BlockActivity Event/] 
            },
        },    
    implementation_type => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'No',
        default_value     => 'No',        
        extra             => { 
            list          => [qw/No Tool Task SubFlow Reference/] 
            },
        },    
    event_type => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'No',
        default_value     => 'No',
        extra             => {
            list          => [qw/No Start Intermediate End/]
            },
        },
    description => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    start_mode => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'Automatic',
        default_value     => 'Automatic',        
        extra             => { 
            list          => [qw/Automatic Manual/] 
            },
        },
    finish_mode => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'Automatic',
        default_value     => 'Automatic',        
        extra             => { 
            list          => [qw/Automatic Manual/] 
            },
        },
    priority => {
        data_type         => 'BIGINT',
        default_value     => 0,
        is_nullable       => 0,
        size              => 21
        },    
    start_quantity => {
        data_type         => 'INT',
        default_value     => 1,
        size              => 3,
        is_nullable       => 1,
        },    
    completion_quantity => {
        data_type         => 'INT',
        default_value     => 1,
        size              => 3,
        is_nullable       => 1,
        },    
    documentation_url => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    icon_url => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },    
    join_type => {
        data_type         => 'ENUM',
        is_nullable       => 1,
        default           => 'NONE',
        default_value     => 'NONE',
        extra             => { 
            list => [qw/NONE AND XOR OR Exclusive Inclusive Parallel Complex/] 
            },
        },
    join_type_exclusive => {
        data_type         => 'ENUM',
        is_nullable       => 1,
        default           => 'Data',
        default_value     => 'Data',
        extra             => { 
            list          => [qw/Data Event/] 
            },
        },
    split_type => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'NONE',
        default_value     => 'NONE',        
        extra             => { 
            list => [qw/NONE AND XOR OR Exclusive Inclusive Parallel Complex/] 
            },
        },    
    split_type_exclusive => {
        data_type         => 'ENUM',
        is_nullable       => 1,
        default           => 'Data',
        default_value     => 'Data',
        extra             => { 
            list          => [qw/Data Event/] 
            },
        },    
    event_attr => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },
    data_fields => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },
    input_sets => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },
    output_sets => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },    
    assignments => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },    
    extended_attr => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },    
    );

__PACKAGE__->set_primary_key('activity_id');

#__PACKAGE__->add_unique_constraint( [qw/process_id activity_uid/] );

__PACKAGE__->belongs_to(
    process => 'BPM::Engine::Store::Result::Process', 'process_id'
    );

# transitions
__PACKAGE__->has_many(
    transitions_in => 'BPM::Engine::Store::Result::Transition', 
    { 'foreign.to_activity_id' => 'self.activity_id' }
    );
__PACKAGE__->many_to_many(
    prev_activities => 'transitions_in', 'from_activity'
    );
__PACKAGE__->has_many(
    transitions => 'BPM::Engine::Store::Result::Transition', 
    { 'foreign.from_activity_id' => 'self.activity_id' }
    );
__PACKAGE__->many_to_many(
    next_activities => 'transitions', 'to_activity'
    );
__PACKAGE__->has_many(
    transition_refs => 'BPM::Engine::Store::Result::TransitionRef',
    'activity_id'
    );

# deadlines
__PACKAGE__->has_many(
    deadlines => 'BPM::Engine::Store::Result::ActivityDeadline',
    'activity_id'
    );

# performers and participants
__PACKAGE__->has_many(
    performers => 'BPM::Engine::Store::Result::Performer',
    { 'foreign.container_id' => 'self.activity_id' },
    { where => { performer_scope => 'Activity' } }
    );

__PACKAGE__->many_to_many(
    participants => 'performers', 'participant'
    );

# tasks
__PACKAGE__->has_many(
    tasks => 'BPM::Engine::Store::Result::ActivityTask', 'activity_id'
    );

# instances
__PACKAGE__->has_many(
    instances => 'BPM::Engine::Store::Result::ActivityInstance', 'activity_id'
    );

sub new {
    my ($class, $attrs) = @_;

    $attrs->{activity_name} ||= $attrs->{activity_uid};

    return $class->next::method($attrs);
    }

sub store_column {
    my ($self, $name, $value) = @_;
    
    if ($name eq 'activity_uid') {
        $value = join( '_', split( /\s+/, $value ) ); #lc?
        }
    
    $self->next::method( $name, $value );
    }


sub transitions { } # for the role to be happy

sub has_transition {
    my ($self, $transition) = @_;
    $self->find_related(transitions => $transition->id);
    }

sub has_transitions {
    my ($self, @transitions) = @_;
    $self->search_related(
        transitions => [ map { $_->id } @transitions ]
        )->count == @transitions;
    }

sub transitions_in_by_ref {
    my ($self) = @_;
    return $self->result_source->schema->resultset('Transition')->search(
        { 'me.from_activity_id' => $self->id,
          'transition_refs.split_or_join' => 'JOIN',
        },
        { prefetch     => 'transition_refs',
          order_by  => ['transition_refs.position'],
        });
    }

sub transitions_by_ref {
    my ($self) = @_;
    
    return $self->result_source->schema->resultset('Transition')->search(
        { 'me.from_activity_id' => $self->id,
          'transition_refs.split_or_join' => 'SPLIT',
        },
        { prefetch     => 'transition_refs',
          order_by  => ['transition_refs.position'],
        });
    }

sub is_start_activity {
    my $self = shift;
    #$g->is_source_vertex($v)    
    return $self->transitions_in->count == 0 ? 1 : 0;
    }

sub is_end_activity {
    my $self = shift;    
    #$g->is_sink_vertex($v)
    return $self->transitions->count == 0 ? 1 : 0;
    }

#-- start/finish mode shortcuts

sub is_auto_start {
    shift->start_mode =~ /^automatic$/i ? 1 : 0;
    }

sub is_auto_finish {
    shift->finish_mode =~ /^automatic$/i ? 1 : 0;
    }

#-- activity_type shortcuts

sub is_implementation_type {
    shift->activity_type =~ /^implementation$/i ? 1 : 0;
    }

sub is_route_type {
    shift->activity_type =~ /^route$/i ? 1 : 0;
    }

sub is_block_type {
    shift->activity_type =~ /^blockactivity$/i ? 1 : 0;
    }

sub is_event_type {
    shift->activity_type =~ /^event$/i ? 1 : 0;
    }

#-- splits and joins

sub is_split {
    my $self = shift;
    return $self->split_type eq 'NONE' ? 0 : 1;
    }

sub is_or_split {
    my $self = shift;
    return $self->split_type =~ /^(OR|Inclusive)$/ ? 1 : 0;
    }

sub is_xor_split {
    my $self = shift;
    return $self->split_type =~ /^(XOR|Exclusive)$/ ? 1 : 0;
    }

sub is_and_split {
    my $self = shift;
    return $self->split_type =~ /^(AND|Parallel)$/ ? 1 : 0;
    }

sub is_complex_split {
    my $self = shift;
    return $self->split_type eq 'Complex' ? 1 : 0;
    }

sub is_join {
    my $self = shift;
    return $self->join_type eq 'NONE' ? 0 : 1;
    }

sub is_or_join {
    my $self = shift;
    return $self->join_type =~ /^(OR|Inclusive)$/ ? 1 : 0;
    }

sub is_xor_join {
    my $self = shift;
    return $self->join_type =~ /^(XOR|Exclusive)$/ ? 1 : 0;
    }

sub is_and_join {
    my $self = shift;
    return $self->join_type =~ /^(AND|Parallel)$/ ? 1 : 0;
    }

sub is_complex_join {
    my $self = shift;
    return $self->join_type eq 'Complex' ? 1 : 0;
    }

#-- implementation_type shortcuts (No Tool Task SubFlow Reference)

sub is_impl_no { 
    shift->implementation_type =~ /^no$/i ? 1 : 0;
    }

sub is_impl_task {
    shift->implementation_type =~ /^task|tool$/i ? 1 : 0;
    }

sub is_impl_subflow {
    shift->implementation_type =~ /^subflow$/i ? 1 : 0;
    }

sub is_impl_reference {
    shift->implementation_type =~ /^reference$/i ? 1 : 0;
    }

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
__END__