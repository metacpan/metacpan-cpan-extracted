use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;

plan tests => 1;

my $d2_subs = qr{
    (
       ClassHooks |
       PluginKeyword |
       dancer_app |
       execute_plugin_hook |
       hook |
       keywords |
       on_plugin_import |
       plugin_args |
       plugin_setting |
       register |
       register_hook |
       register_plugin |
       request |
       var
    )
}x;
pod_coverage_ok(
    "Dancer2::Plugin::Passphrase",
    { also_private => [ $d2_subs ] },
    "Dancer2::Plugin::Passphrase has full POD coverage"
);
