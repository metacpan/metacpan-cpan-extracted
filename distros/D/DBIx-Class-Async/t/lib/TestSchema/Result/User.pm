package TestSchema::Result::User;

use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/Async::ResultComponent Core/);
__PACKAGE__->table('users');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    name => {
        data_type   => 'varchar',
        size        => 100,
        is_nullable => 0,
    },
    email => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1,
    },
    active => {
        data_type     => 'integer',
        is_nullable   => 0,
        default_value => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(user_email => [qw/email/]);
__PACKAGE__->has_many( orders => 'TestSchema::Result::Order', 'user_id');

1;
