package BPM::Engine::Store::Result::ProcessInstanceState;
BEGIN {
    $BPM::Engine::Store::Result::ProcessInstanceState::VERSION   = '0.01';
    $BPM::Engine::Store::Result::ProcessInstanceState::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
use MooseX::NonMoose;
extends qw/DBIx::Class::Core/;
with qw/Class::Workflow::Instance/;

__PACKAGE__->load_components(qw/TimeStamp/);
__PACKAGE__->table('wfe_process_instance_journal');
__PACKAGE__->add_columns(
    event_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 },
        size              => 11,
        },
    process_instance_id => {
        data_type         => 'INT',
        is_nullable       => 0,
        size              => 11,
        is_foreign_key    => 1,
        extras            => { unsigned => 1 },
        },
    state => {    # the state the instance is currently in
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        default           => 'open',
        default_value     => 'open',
        },
    transition => { # the transition this instance is a result of
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        },
    prev => {
        data_type         => 'INT',
        is_nullable       => 1,
        size              => 11,        
        },
    created => {
        data_type         => 'DATETIME',
        is_nullable       => 1,
        set_on_create     => 1,
        timezone          => 'UTC',
        },    
    );

__PACKAGE__->set_primary_key('event_id');

__PACKAGE__->belongs_to(
    process_instance => 'BPM::Engine::Store::Result::ProcessInstance', 
    'process_instance_id'
    );

__PACKAGE__->belongs_to( prev => __PACKAGE__ ); # history

__PACKAGE__->might_have(
    next => __PACKAGE__,   { 'foreign.prev' => 'self.event_id' }
    );

__PACKAGE__->inflate_column('state', {
    inflate => sub {
        my ($value, $self) = @_;
        return $self->process_instance->workflow->get_state($value);
        },
    deflate => sub {
        shift->stringify
        },
    });

sub clone {
    my ($self, %fields) = @_;
    return $self->copy({%fields});
    }

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
__END__