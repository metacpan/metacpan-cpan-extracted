

use strict;
use warnings;

use Test::More 'tests' => 45;
my $Per_Driver_Tests = 15;


use Config::Context;

my %Config_Text;

$Config_Text{'ConfigGeneral'} = <<'EOF';
    private_area = 0
    client_area  = 0

    <page_settings>
        title       = "The Widget Emporium"
        logo        = logo.gif
        advanced_ui = 0
    </page_settings>

    <Location /admin>
        private_area = 1
        <page_settings>
            title       = "The Widget Emporium - Admin Area"
            logo        = admin_logo.gif
            advanced_ui = 1
        </page_settings>
    </Location>

    <Location /clients>
        client_area  = 1
        <page_settings>
            title = "The Widget Emporium - Wholesalers"
            logo  = client_logo.gif
        </page_settings>
    </Location>

EOF

$Config_Text{'ConfigScoped'} = <<'EOF';

    page_settings {
        title       = "The Widget Emporium"
        logo        = logo.gif
        advanced_ui = 0
    }

    Location /admin {
        private_area = 1
        page_settings = {
            title       = "The Widget Emporium - Admin Area"
            logo        = admin_logo.gif
            advanced_ui = 1
        }
    }

    Location /clients {
        client_area  = 1
        page_settings = {
            title = "The Widget Emporium - Wholesalers"
            logo  = client_logo.gif
        }
    }

EOF

$Config_Text{'XMLSimple'} = <<'EOF';
<opt>
    <private_area>0</private_area>
    <client_area>0</client_area>

    <page_settings>
        <title>The Widget Emporium</title>
        <logo>logo.gif</logo>
        <advanced_ui>0</advanced_ui>
    </page_settings>

    <Location name="/admin">
        <private_area>1</private_area>
        <page_settings>
            <title>The Widget Emporium - Admin Area</title>
            <logo>admin_logo.gif</logo>
            <advanced_ui>1</advanced_ui>
        </page_settings>
    </Location>

    <Location name="/clients">
        <client_area>1</client_area>
        <page_settings>
            <title>The Widget Emporium - Wholesalers</title>
            <logo>client_logo.gif</logo>
        </page_settings>
    </Location>
   </opt>

EOF

sub runtests {
    my $driver = shift;

    my $conf = Config::Context->new(
        driver => $driver,
        string => $Config_Text{$driver},
        match_sections => [
            {
                name       => 'Location',
                match_type => 'path',
            },
        ],
        driver_options => {
            ConfigGeneral => {
                -CComments       => 0,
            }
        }

    );

    my %config = $conf->context('/admin');

    is($config{'private_area'},                 1,                     "$driver: [/admin] private_area:              1");
    ok(!$config{'client_area'},                                        "$driver: [/admin] client_area:               0");
    is($config{'page_settings'}{'title'},       'The Widget Emporium - Admin Area',
                                                                       "$driver: [/admin] page_settings.title:       The Widget Emporium - Admin Area");
    is($config{'page_settings'}{'logo'},        'admin_logo.gif',      "$driver: [/admin] page_settings.logo:        admin_logo.gif");
    is($config{'page_settings'}{'advanced_ui'}, 1,                     "$driver: [/admin] page_settings.advanced_ui: 1");

    %config = $conf->context('/clients');

    ok(!$config{'private_area'},                                       "$driver: [/clients] private_area:              0");
    is($config{'client_area'},                  1,                     "$driver: [/clients] client_area:               1");
    is($config{'page_settings'}{'title'},       'The Widget Emporium - Wholesalers',
                                                                       "$driver: [/clients] page_settings.title:       The Widget Emporium - Wholesalers");
    is($config{'page_settings'}{'logo'},        'client_logo.gif',     "$driver: [/clients] page_settings.logo:        client_logo.gif");
    ok(!$config{'page_settings'}{'advanced_ui'},                       "$driver: [/clients] page_settings.advanced_ui: 0");

    %config = $conf->context('/public');

    ok(!$config{'private_area'},                                        "$driver: [/public] private_area:              0");
    ok(!$config{'client_area'},                                         "$driver: [/public] client_area:               0");
    is($config{'page_settings'}{'title'},       'The Widget Emporium', "$driver: [/public] page_settings.title:       The Widget Emporium");
    is($config{'page_settings'}{'logo'},        'logo.gif',            "$driver: [/public] page_settings.logo:        logo.gif");
    ok(!$config{'page_settings'}{'advanced_ui'},                       "$driver: [/public] page_settings.advanced_ui: 0");
}

SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        runtests('ConfigGeneral');
    }
    else {
        skip "Config::General not installed", $Per_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        runtests('ConfigScoped');
    }
    else {
        skip "Config::Scoped not installed", $Per_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('XMLSimple')) {
        runtests('XMLSimple');
    }
    else {
        skip "XML::Simple, XML::SAX or XML::Filter::XInclude not installed", $Per_Driver_Tests;
    }
}

sub test_driver_prereqs {
    my $driver = shift;
    my $driver_module = 'Config::Context::' . $driver;
    eval "require $driver_module;";
    die $@ if $@;

    eval "require $driver_module;";
    my @required_modules = $driver_module->config_modules;

    foreach (@required_modules) {
        eval "require $_;";
        if ($@) {
            return;
        }
    }
    return 1;

}
