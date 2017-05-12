package BPM::Engine::Store::Result::ActivityInstanceAttribute;
BEGIN {
    $BPM::Engine::Store::Result::ActivityInstanceAttribute::VERSION   = '0.01';
    $BPM::Engine::Store::Result::ActivityInstanceAttribute::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
extends qw/BPM::Engine::Store::Result/;

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('wfe_activity_instance_attr');
__PACKAGE__->add_columns(
    activity_instance_id => {
        data_type         => 'INT',
        is_nullable       => 0,        
        size              => 11,
        is_foreign_key    => 1,
        extras            => { unsigned => 1 },
        },    
    name => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 0,
        },
    type => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },
    mode => {
        data_type         => 'VARCHAR',
        size              => 20,
        is_nullable       => 1,
        },
    value => {
        data_type         => 'TEXT',
        is_nullable       => 1,
        },
    );

__PACKAGE__->set_primary_key(qw/ activity_instance_id name /);

__PACKAGE__->belongs_to(
    activity_instance => 'BPM::Engine::Store::Result::ActivityInstance', 
    'activity_instance_id'
    );

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
__END__