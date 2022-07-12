#! perl -I. -w
use t::Test::abeltje;

use Test::Pod::Coverage;

Test::Warnings->import(':no_end_test');

my @ignore_words = sort {
    length($b) <=> length($a) ||
    $a cmp $b
} map {chomp($_); $_} <DATA>;

all_pod_coverage_ok({ trustme => \@ignore_words });

__DATA__
ClassHooks
PluginKeyword
dancer_app
execute_plugin_hook
hook
keywords
on_plugin_import
plugin_args
plugin_setting
register
register_hook
register_plugin
request
var
