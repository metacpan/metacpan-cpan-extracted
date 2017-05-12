package # hide from PAUSE
    DemoApp;

use Catalyst qw/-Debug
                ConfigLoader
                Unicode::Encoding
                AutoCRUD/;

DemoApp->config(
    root => "$FindBin::Bin/root",
    'Plugin::ConfigLoader' => { file => "$FindBin::Bin/demo.conf" },
);

DemoApp->setup();
1;
