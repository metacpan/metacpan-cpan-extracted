package BPM::Engine::Store::Result::Performer;
BEGIN {
    $BPM::Engine::Store::Result::Performer::VERSION   = '0.01';
    $BPM::Engine::Store::Result::Performer::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('wfd_performer');
__PACKAGE__->add_columns(
    performer_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },
    participant_id => {
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },
    container_id => {
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },
    performer_scope => {
        data_type         => 'ENUM',
        is_nullable       => 1,
        default           => 'Activity',
        default_value     => 'Activity',
        extra             => { list => [qw/ Activity Task Lane /] },
        },    
    );
__PACKAGE__->set_primary_key('performer_id');

__PACKAGE__->might_have(
    'activity' => 'BPM::Engine::Store::Result::Activity',
    { 'foreign.activity_id' => 'self.container_id' },
    { where => { performer_scope => 'Activity' } }
    );

# TaskUser, TaskManual
__PACKAGE__->might_have(
    'task' => 'BPM::Engine::Store::Result::ActivityTask',
    { 'foreign.task_id' => 'self.container_id' },
    { where => { performer_scope => 'Task' } }
    );

__PACKAGE__->belongs_to(
    participant => 'BPM::Engine::Store::Result::Participant', 'participant_id'
    );

1;
__END__