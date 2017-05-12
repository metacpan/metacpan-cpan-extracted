# SmartHouse - A Web-based X10 Device Controller in Perl.
# This demo is based on a college lab assignment.  It doesn't actually 
# control any hardware, but is a simple web interface for such a program 
# should one want to extend it in that manner.  This is meant to show how 
# CGI::Portable can be used in a wide variety of environments, not just 
# ordinary database or web sites.  If you wanted to extend it then you 
# should use modules like ControlX10::CM17, ControlX10::CM11, or 
# Device::SerialPort.  On the other hand, if you want a very complete 
# (and complicated) Perl solution then you can download Bruce Winter's 
# free open-source MisterHouse instead at "http://www.misterhouse.net".

package DemoX10;
use strict;
use warnings;
use CGI::Portable;

sub main {
	my ($class, $globals) = @_;
 	
	my $current_frame = $globals->current_user_path_element();
	 	
 	SWITCH: {
	 	unless( $current_frame ) {
	 		$globals->set_page_frameset_attributes( { 
	 			cols => '30%,70%', border => 1 } );
	 		$globals->set_page_frameset( [map { 
	 			{ name => $_, src => $globals->url_as_string( $_ ), } 
	 			} qw( menu detail )] );
			$globals->page_title( 'Smart House of 2001 by Darren Duncan' );
			$globals->set_page_body( "<H1>Your Browser Doesn't Do Frames</H1>" );
	 		last SWITCH;
	 	}
	
		if( $current_frame eq 'menu' ) {
			$class->menu_frame( $globals );
			$globals->set_page_style_code( 'BODY {background-color: yellow}' );
			last SWITCH;
		}
	
		if( $current_frame eq 'detail' ) {
			$globals->inc_user_path_level();
			$class->detail_frame( $globals );
			$globals->dec_user_path_level();
			$globals->set_page_style_code( 'BODY {background-color: white}' );
			last SWITCH;
		}
	
		$globals->set_page_body( 
			"<H1>Bad Frame Address of '$current_frame' - BAD</H1>" );
	}
	 	
	$globals->http_window_target( $current_frame );
}

sub menu_frame {
	my ($class, $globals) = @_;

	my $rh_handlers = $globals->pref( 'handlers' );
	ref( $rh_handlers ) eq 'HASH' or $rh_handlers = {};
	
	$globals->navigate_url_path( 'detail' );
	
	my @menu_html = ();
	
	foreach my $device (keys %{$rh_handlers}) {
		my $rh_handler = $rh_handlers->{$device};
		ref( $rh_handler ) eq 'HASH' or next;

		my $menu_name = $rh_handler->{'menu_name'};
		my $menu_url = $globals->url_as_string( $device );
		
		push( @menu_html, "<A HREF=\"$menu_url\">$menu_name</A>" );
	}
	
	$globals->set_page_body( "<H1>Device List</H1>\n", 
		"<P>", join( "<BR>\n", @menu_html ), "</P>\n" );
}

sub detail_frame {
	my ($class, $globals) = @_;

	my $rh_handlers = $globals->pref( 'handlers' );
	ref( $rh_handlers ) eq 'HASH' or $rh_handlers = {};
	
	$globals->navigate_url_path( 'detail' );
	
	SWITCH: {
		my $current_device = $globals->current_user_path_element();
	 	
		unless( $current_device ) {
			$globals->set_page_body( <<__endquote );
<H1>Welcome</H1>
<P>Welcome to the Smart House of 2001 by Darren Duncan.  Please choose a device 
that you wish to control from the menu on the left.</P>
__endquote
			last SWITCH;
		}
	
		my $rh_handler = $rh_handlers->{$current_device};

		unless( ref( $rh_handler ) eq 'HASH' ) {
			$globals->set_page_body( <<__endquote );
<H1>Bad Menu Choice</H1>
<P>The device you chose from the menu, '$current_device', doesn't seem to be in 
the list of devices that we know about.  If you entered that url manually then 
please choose from the menu instead.  If you did choose from the menu then there 
is something wrong with your configuration file.</P>
__endquote
			last SWITCH;
		}
		
		my $device_context = $globals->make_new_context();
		$device_context->inc_user_path_level();
		$device_context->navigate_url_path( $current_device );
		$device_context->set_prefs( $rh_handler->{'mod_prefs'} );
		$device_context->call_component( $rh_handler->{'mod_name'} );
		$globals->take_context_output( $device_context );
		
		$globals->prepend_page_body( "<H1>Device Control</H1>\n", 
			"<P><STRONG>", $rh_handler->{'menu_name'}, "</STRONG></P>\n" );
	}
}

1;
