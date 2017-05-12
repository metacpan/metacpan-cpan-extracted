package BPM::Engine::Store::Result::Participant;
BEGIN {
    $BPM::Engine::Store::Result::Participant::VERSION   = '0.01';
    $BPM::Engine::Store::Result::Participant::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/InflateColumn::Serializer Core /);
__PACKAGE__->table('wfd_participant');
__PACKAGE__->add_columns(
    participant_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },
    participant_uid => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 0,
        },
    participant_name => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    description => {
        data_type         => 'VARCHAR',
        size              => 255,
        is_nullable       => 1,
        },
    participant_type => {
        data_type         => 'ENUM',
        is_nullable       => 1,
        default           => 'SYSTEM',
        default_value     => 'SYSTEM',
        extra             => { list => [qw/
            RESOURCE_SET RESOURCE ROLE ORGANIZATIONAL_UNIT HUMAN SYSTEM
            /] },
        },
    participant_scope => {
        data_type         => 'ENUM',
        is_nullable       => 1,
        default           => 'Package',
        default_value     => 'Package',
        extra             => { list => [qw/ Package Process /] },
        },    
    parent_node => {
        data_type         => 'CHAR',
        size              => 36,
        is_nullable       => 0,
        is_foreign_key    => 1,
        },    
    attributes => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        serializer_class  => 'JSON',
        },
    );

__PACKAGE__->set_primary_key(qw/participant_id/);


__PACKAGE__->might_have(
    'package' => 'BPM::Engine::Store::Result::Package',
    { 'foreign.package_id' => 'self.parent_node' },
    { participant_scope => 'Package' }
    );

__PACKAGE__->might_have(
    'process' => 'BPM::Engine::Store::Result::Process',
    { 'foreign.process_id' => 'self.parent_node' },
    { participant_scope => 'Process' }
    );


1;
__END__