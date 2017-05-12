

use strict;
use warnings;

use Test::More 'no_plan';


use Config::General::Match;

my $conf_text = <<EOF;
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

my $conf = Config::General::Match->new(
    -MatchSections => [
        {
            -Name          => 'Location',
            -MatchType     => 'path',
        },
    ],
    -String          => $conf_text,
    -CComments       => 0,

);

my %config = $conf->getall_matching('/admin');

is($config{'private_area'},                 1,                     '[/admin] private_area:              1');
is($config{'client_area'},                  0,                     '[/admin] client_area:               0');
is($config{'page_settings'}{'title'},       'The Widget Emporium - Admin Area',
                                                                   '[/admin] page_settings.title:       The Widget Emporium - Admin Area');
is($config{'page_settings'}{'logo'},        'admin_logo.gif',      '[/admin] page_settings.logo:        admin_logo.gif');
is($config{'page_settings'}{'advanced_ui'}, 1,                     '[/admin] page_settings.advanced_ui: 1');

%config = $conf->getall_matching('/clients');

is($config{'private_area'},                 0,                     '[/clients] private_area:              0');
is($config{'client_area'},                  1,                     '[/clients] client_area:               1');
is($config{'page_settings'}{'title'},       'The Widget Emporium - Wholesalers',
                                                                   '[/clients] page_settings.title:       The Widget Emporium - Wholesalers');
is($config{'page_settings'}{'logo'},        'client_logo.gif',     '[/clients] page_settings.logo:        client_logo.gif');
is($config{'page_settings'}{'advanced_ui'}, 0,                     '[/clients] page_settings.advanced_ui: 0');

%config = $conf->getall_matching('/public');

is($config{'private_area'},                 0,                     '[/public] private_area:              0');
is($config{'client_area'},                  0,                     '[/public] client_area:               0');
is($config{'page_settings'}{'title'},       'The Widget Emporium', '[/public] page_settings.title:       The Widget Emporium');
is($config{'page_settings'}{'logo'},        'logo.gif',            '[/public] page_settings.logo:        logo.gif');
is($config{'page_settings'}{'advanced_ui'}, 0,                     '[/public] page_settings.advanced_ui: 0');
