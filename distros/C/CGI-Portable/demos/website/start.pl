#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/darren/perl_lib';

require CGI::Portable;
my $globals = CGI::Portable->new();

use Cwd;
$globals->file_path_root( cwd() );  # let us default to current working dir
$globals->file_path_delimiter( $^O=~/Mac/i ? ":" : $^O=~/Win/i ? "\\" : "/" );

require CGI::Portable::AdapterCGI;
my $io = CGI::Portable::AdapterCGI->new();
$io->fetch_user_input( $globals );

if( $globals->user_query_param( 'debugging' ) eq 'on' ) {
	$globals->is_debug( 1 );
	$globals->url_query_param( 'debugging', 'on' );
}

$globals->default_application_title( 'Demo Web Site' );
$globals->default_maintainer_name( 'Darren Duncan' );
$globals->default_maintainer_email_address( 'demo@DarrenDuncan.net' );
$globals->default_maintainer_email_screen_url_path( '/mailme' );

my $content = $globals->make_new_context();
$content->current_user_path_level( 1 );
$content->navigate_file_path( 'content' );
$content->set_prefs( 'content_prefs.pl' );
$content->call_component( 'CGI::Portable::AppSplitScreen' );
$globals->take_context_output( $content );

my $usage = $globals->make_new_context();
$usage->http_redirect_url( $globals->http_redirect_url() );
$usage->navigate_file_path( $globals->is_debug() ? 'usage_debug' : 'usage' );
$usage->set_prefs( '../usage_prefs.pl' );
$usage->call_component( 'DemoUsage' );
$globals->take_context_output( $usage, 1 );

if( $globals->is_debug() ) {
	$globals->append_page_body( <<__endquote );
<p>Debugging is currently turned on.</p>
__endquote
}

$globals->search_and_replace_url_path_tokens( '__url_path__' );

$io->send_user_output( $globals );

1;
