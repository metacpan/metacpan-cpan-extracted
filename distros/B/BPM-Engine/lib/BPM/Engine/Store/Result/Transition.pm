package BPM::Engine::Store::Result::Transition;
BEGIN {
    $BPM::Engine::Store::Result::Transition::VERSION   = '0.01';
    $BPM::Engine::Store::Result::Transition::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
extends qw/BPM::Engine::Store::Result/;
with qw/
           BPM::Engine::Store::ResultBase::ProcessTransition
           BPM::Engine::Store::ResultRole::WithAssignments
       /;

#__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('wfd_transition');
__PACKAGE__->add_columns(
    transition_id => {
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
    from_activity_id => { # state
        data_type         => 'INT',
        is_nullable       => 0,
        is_foreign_key    => 1,
        },
    to_activity_id => {   # to_state
        data_type         => 'INT',
        is_nullable       => 0,
        is_foreign_key    => 1,
        },    
    transition_uid => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        },
    transition_name => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    description => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    condition_type => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'NONE',
        default_value     => 'NONE',
        extra             => { list => [qw/
            NONE CONDITION OTHERWISE EXCEPTION DEFAULTEXCEPTION
            /] },
        },    
    condition_expr => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        },
    quantity => {
        data_type         => 'INT',
        default_value     => 1,        
        size              => 3,
        is_nullable       => 1,
        },    
    assignments => {
        data_type         => 'TEXT',
        #size              => 255,
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },    
    class => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    is_back_edge => {
        data_type         => 'TINYINT',
        default_value     => 0,
        is_nullable       => 1,
        size              => 1,
        extras            => { unsigned => 1 }
        },    
    );

__PACKAGE__->set_primary_key('transition_id');

__PACKAGE__->add_unique_constraint(
    [qw/process_id from_activity_id to_activity_id/]
    );

__PACKAGE__->belongs_to( 
    process => 'BPM::Engine::Store::Result::Process', 'process_id'
    );

__PACKAGE__->belongs_to( 
    from_activity => 'BPM::Engine::Store::Result::Activity',
    { 'foreign.activity_id' => 'self.from_activity_id' }
    );

__PACKAGE__->belongs_to(
    to_activity => 'BPM::Engine::Store::Result::Activity', 
    { 'foreign.activity_id' => 'self.to_activity_id' }
    );

__PACKAGE__->has_many(
    transition_refs => 'BPM::Engine::Store::Result::TransitionRef',
    'transition_id'
    );

__PACKAGE__->might_have(
    deadline => 'BPM::Engine::Store::Result::ActivityDeadline',
    { 'foreign.exception_id' => 'self.transition_id' } 
    );

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

sub from_split {
    my $self = shift;
    return $self->transition_refs({ 
        activity_id => $self->from_activity_id 
        })->first;
    }

sub to_join {
    my $self = shift;
    return $self->transition_refs({ 
        activity_id => $self->to_activity_id 
        })->first;
    }

1;
__END__

    process_id => {
        data_type         => 'INT',
        is_nullable       => 0,
        is_foreign_key    => 1,
        extras            => { unsigned => 1 },
        },