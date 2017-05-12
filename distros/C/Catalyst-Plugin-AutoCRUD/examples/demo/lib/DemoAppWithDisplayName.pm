package # hide from PAUSE
    DemoAppWithDisplayName;

use Catalyst qw/-Debug
                ConfigLoader
                Unicode::Encoding
                AutoCRUD/;

DemoAppWithDisplayName->config(
    root => "$FindBin::Bin/root",
    'Plugin::ConfigLoader' => { file => "$FindBin::Bin/demo_with_display_name.conf" },
);

DemoAppWithDisplayName->setup();
1;
