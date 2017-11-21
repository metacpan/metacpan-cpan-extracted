use strict; use warnings;

use Test::More;
use Test::Pod::Coverage;
use Pod::Coverage::CountParents;

my $module  = 'Dancer2::Plugin::SyntaxHighlight::Perl';
my $params  = {
    also_private => [ qr/BUILD/ ],
    trustme      => [ qw/
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
    / ],
};

pod_coverage_ok( $module, $params );

done_testing;
