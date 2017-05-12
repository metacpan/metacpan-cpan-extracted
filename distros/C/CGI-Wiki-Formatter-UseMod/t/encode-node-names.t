use strict;
use CGI::Wiki::Formatter::UseMod;
use Test::More tests => 4;

my $formatter = CGI::Wiki::Formatter::UseMod->new( munge_urls => 1 );
is( $formatter->node_name_to_node_param( "test page" ),
    "Test_Page", "->node_name_to_node_param forces ucfirst by default" );

$formatter = CGI::Wiki::Formatter::UseMod->new( force_ucfirst_nodes => 0,
                                                munge_urls          => 1 );
is( $formatter->node_name_to_node_param( "test page" ),
    "test_page", "...but not if force_ucfirst_nodes set to 0" );

$formatter = CGI::Wiki::Formatter::UseMod->new;
is( $formatter->node_name_to_node_param( "Home Page" ), "Home Page",
    "->node_name_to_node_param does nothing if munge_urls not true" );
is( $formatter->node_param_to_node_name( "Home_Page" ), "Home_Page",
    "->node_param_to_node_name does nothing if munge_urls not true" );

