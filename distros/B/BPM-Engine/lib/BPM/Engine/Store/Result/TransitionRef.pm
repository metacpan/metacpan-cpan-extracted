package BPM::Engine::Store::Result::TransitionRef;
BEGIN {
    $BPM::Engine::Store::Result::TransitionRef::VERSION   = '0.01';
    $BPM::Engine::Store::Result::TransitionRef::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('wfd_transition_ref');
__PACKAGE__->add_columns(
    activity_id => {
        data_type         => 'INT',
        is_nullable       => 0,
        is_foreign_key    => 1,
        },
    transition_id => {
        data_type         => 'INT',
        is_nullable       => 0,
        is_foreign_key    => 1,
        },
    split_or_join => {
        data_type         => 'ENUM',
        is_nullable       => 0,
        extra             => { list => [qw/
            SPLIT JOIN
            /] },
        },   
    position => {
        data_type         => 'TINYINT',
        default_value     => 0,
        is_nullable       => 0,
        size              => 3,
        extras            => { unsigned => 1 }
        },     
    );

__PACKAGE__->set_primary_key(qw/ activity_id transition_id split_or_join /);

__PACKAGE__->belongs_to( activity => 'BPM::Engine::Store::Result::Activity',
    { 'foreign.activity_id' => 'self.activity_id' } );

__PACKAGE__->belongs_to( transition => 'BPM::Engine::Store::Result::Transition',
    'transition_id' );

1;
__END__
