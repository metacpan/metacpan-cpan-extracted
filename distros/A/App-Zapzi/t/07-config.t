#!perl
use Test::Most;

use lib qw(t/lib);
use ZapziTestDatabase;

use App::Zapzi;
use App::Zapzi::Config;
use App::Zapzi::UserConfig;

test_can();

my ($test_dir, $app) = ZapziTestDatabase::get_test_app();

test_get();
test_set();
test_get_keys();
test_delete();
test_userconfig_init();
test_userconfig_data();
test_userconfig_get();
test_userconfig_set();

done_testing();

sub test_can
{
    can_ok( 'App::Zapzi::Config',
            qw(get set get_keys delete) );
    can_ok( 'App::Zapzi::UserConfig',
            qw(get set get_doc get_user_configurable_keys) );
}

sub test_get
{
    ok( App::Zapzi::Config::get('schema_version'),
        'Can read a defined config value' );

    is( App::Zapzi::Config::get('no_such_key'), undef,
        'An non-existent config key gives undef as value' );

    eval { App::Zapzi::Config::get() };
    like( $@, qr/Key not provided/, 'Key has to be provided to get' );

    eval { App::Zapzi::Config::get('') };
    like( $@, qr/Key not provided/, 'Non-empty key has to be provided to get' );
}

sub test_set
{
    ok( App::Zapzi::Config::set('foo', 'bar'), 'Can set a new key' );
    is( App::Zapzi::Config::get('foo'), 'bar',
        'Can get a config value after setting it' );

    ok( App::Zapzi::Config::set('foo', 'baz'), 'Can update a key' );
    is( App::Zapzi::Config::get('foo'), 'baz',
        'Can get a config value after updating it' );

    ok( App::Zapzi::Config::set('xyz', ''), 'Can set a value to blank' );
    is( App::Zapzi::Config::get('xyz'), '',
        'Can get a blank config value' );

    eval { App::Zapzi::Config::set() };
    like( $@, qr/need to be provided/, 'Key has to be provided to set' );

    eval { App::Zapzi::Config::set('abc') };
    like( $@, qr/need to be provided/, 'Value has to be provided to set' );
}

sub test_get_keys
{
    my @keys = App::Zapzi::Config::get_keys();
    ok( scalar(@keys) >= 3, 'get_keys returns a list of keys' );
    ok( grep(/foo/, @keys), 'Can find a key we set' );
}

sub test_delete
{
    ok( App::Zapzi::Config::set('option_x', 'abc'), 'Can set a key' );

    is( App::Zapzi::Config::get('option_x'), 'abc',
        'Can get a config value after setting it' );

    ok( App::Zapzi::Config::delete('option_x'),
        'Can delete a defined config value' );

    is( App::Zapzi::Config::get('option_x'), undef,
        'Key is really deleted after delete' );

    eval { App::Zapzi::Config::delete() };
    like( $@, qr/Key not provided/, 'Key has to be provided to delete' );
}

sub test_userconfig_init
{
    ok( $app->init_config(), 'Initialised user config variables' );
}

sub test_userconfig_data
{
    like( App::Zapzi::UserConfig::get_description('publish_format'),
          qr/^Format to publish eBooks in/,
          'Get description of user config variable' );

    like( App::Zapzi::UserConfig::get_options('publish_format'),
          qr/^EPUB, MOBI/,
          'Get valid options for user config variable' );

    like( App::Zapzi::UserConfig::get_default('publish_format'),
          qr/^MOBI$/,
          'Get default for user config variable' );

    is( ref(App::Zapzi::UserConfig::get_validater('publish_format')),
        'CODE',
        'Get validater sub for user config variable' );

    like( App::Zapzi::UserConfig::get_doc('publish_format'),
          qr/# Format to publish eBooks in.\n# Options: EPUB, /mi,
          'Got documentation for a user config variable' );

    is( App::Zapzi::UserConfig::get_doc('nosuch'), undef,
        'Nonexistent variables have no documentation' );

    is( App::Zapzi::UserConfig::get_doc('schema_version'), undef,
        'Non-user config variables have no documentation' );

    eval { App::Zapzi::UserConfig::get_doc() };
    like( $@, qr/Key not provided/, 'Key has to be provided to get_doc' );

    my @ucks = App::Zapzi::UserConfig::get_user_configurable_keys();
    ok( scalar(@ucks) > 1, 'Can get user configurable keys list' );

    ok( App::Zapzi::UserConfig::get_user_init_configurable_keys(),
        'Can get user init configurable keys list' );
}

sub test_userconfig_get
{
    ok( App::Zapzi::UserConfig::get('publish_format'),
        'Can read a defined config value' );

    is( App::Zapzi::UserConfig::get('no_such_key'), undef,
        'An nonexistent config key gives undef as value' );

    is( App::Zapzi::UserConfig::get('schema_version'), undef,
        'Non-user config variables cannot be got' );

    eval { App::Zapzi::UserConfig::get() };
    like( $@, qr/Key not provided/, 'Key has to be provided to get' );

    eval { App::Zapzi::UserConfig::get('') };
    like( $@, qr/Key not provided/, 'Non-empty key has to be provided to get' );
}

sub test_userconfig_set
{
    ok( App::Zapzi::UserConfig::set('publish_format', 'MOBI'),
        'Can set publish_format to a valid value' );

    ok( App::Zapzi::UserConfig::set('publish_encoding', 'UTF-8'),
        'Can set publish_encoding to a valid value' );

    is( App::Zapzi::UserConfig::set('publish_format', 'mobi'), 'MOBI',
        'Validate canonicalises inputs' );

    is( App::Zapzi::UserConfig::set('publish_format', 'invalid'), undef,
        'Cannot set publish_format to an invalid value' );

    is( App::Zapzi::UserConfig::set('nonesuch', 'abc'), undef,
        'Undefined keys lead to undef output' );

    ok( App::Zapzi::UserConfig::set('deactivate_links', 'Y'),
        'Can set deactivate_links to a valid value' );

    is( App::Zapzi::UserConfig::set('deactivate_links', 'invalid'), undef,
        'Cannot set deactivate_links to an invalid value' );

    is( App::Zapzi::UserConfig::set('schema_version', 333), undef,
        'Cannot set non-user configurable variables' );

    eval { App::Zapzi::UserConfig::set() };
    like( $@, qr/need to be provided/, 'Key has to be provided to validate' );

    eval { App::Zapzi::UserConfig::set('abc') };
    like( $@, qr/need to be provided/, 'Value has to be provided to validate' );
}
