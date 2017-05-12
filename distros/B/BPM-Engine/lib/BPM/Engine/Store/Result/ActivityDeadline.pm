package BPM::Engine::Store::Result::ActivityDeadline;
BEGIN {
    $BPM::Engine::Store::Result::ActivityDeadline::VERSION   = '0.01';
    $BPM::Engine::Store::Result::ActivityDeadline::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('wfd_activity_deadline');
__PACKAGE__->add_columns(
    deadline_id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },
    activity_id => {
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 0,
        extras            => { unsigned => 1 }
        },
    exception_id => {
        data_type         => 'INT',
        is_foreign_key    => 1,
        is_nullable       => 0,        
        },    
    execution => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        default           => 'SYNCHR',
        default_value     => 'SYNCHR',
        extra             => { list => [qw/ SYNCHR ASYNCHR /] },
        },  
    duration => {
        data_type         => 'VARCHAR',
        size              => 64,
        is_nullable       => 1,
        },   
    );

__PACKAGE__->set_primary_key(qw/ deadline_id /);

__PACKAGE__->belongs_to( activity => 'BPM::Engine::Store::Result::Activity',
    { 'foreign.activity_id' => 'self.activity_id' } );

__PACKAGE__->belongs_to( transition => 'BPM::Engine::Store::Result::Transition',
    { 'foreign.transition_id' => 'self.exception_id' } );

1;
__END__