use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::MockObject;
use Dancer2::Plugin::Auth::Extensible::Provider::DBIC;

my $mock = Test::MockObject->new;
$mock->set_true('app');

# instantiate with _source
{
    my $plugin;
    warnings_like(
        sub {
            $plugin = Dancer2::Plugin::Auth::Extensible::Provider::DBIC->new(
                plugin            => $mock,
                users_source      => 'users',
                roles_source      => 'roles',
                user_roles_source => 'user_roles',
            );
        },
        [
            qr/\Qconfig setting "users_source" is deprecated. Use "users_resultset" instead/,
            qr/\Qconfig setting "roles_source" is deprecated. Use "roles_resultset" instead/,
            qr/\Qconfig setting "user_roles_source" is deprecated. Use "user_roles_resultset" instead/,
        ],
        "_source is deprecated"
    );
    isa_ok $plugin, 'Dancer2::Plugin::Auth::Extensible::Provider::DBIC',
        'object created with _source';
    is $plugin->users_resultset,      'Users',     "... and users_resultset got set";
    is $plugin->roles_resultset,      'Roles',     "... and roles_resultset got set";
    is $plugin->user_roles_resultset, 'UserRoles', "... and user_roles_resultset got set";
}

# instantiate with _table
{
    my $plugin;
    warnings_like(
        sub {
            $plugin = Dancer2::Plugin::Auth::Extensible::Provider::DBIC->new(
                plugin           => $mock,
                users_table      => 'users',
                roles_table      => 'roles',
                user_roles_table => 'user_roles',
            );
        },
        [
            qr/\Qconfig setting "users_table" is deprecated. Use "users_resultset" instead/,
            qr/\Qconfig setting "roles_table" is deprecated. Use "roles_resultset" instead/,
            qr/\Qconfig setting "user_roles_table" is deprecated. Use "user_roles_resultset" instead/,
        ],
        "_source is deprecated"
    );
    isa_ok $plugin, 'Dancer2::Plugin::Auth::Extensible::Provider::DBIC',
        'object created with _table';
    is $plugin->users_resultset,      'Users',     "... and users_resultset got set";
    is $plugin->roles_resultset,      'Roles',     "... and roles_resultset got set";
    is $plugin->user_roles_resultset, 'UserRoles', "... and user_roles_resultset got set";
}

done_testing;
