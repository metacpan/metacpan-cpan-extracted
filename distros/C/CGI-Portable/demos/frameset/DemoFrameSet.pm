package DemoFrameSet;
use strict;
use warnings;
use CGI::Portable;

sub main {
	my ($class, $globals) = @_;
 	
 	SWITCH: {
	 	my $current_frame = $globals->current_user_path_element();
	 	
	 	unless( $current_frame ) {
	 		$globals->set_page_frameset_attributes( { 
	 			rows => '40%,60%', cols => '40%,60%', border => 1 } );
	 		$globals->set_page_frameset( [map { 
	 			{ name => $_, src => $globals->url_as_string( $_ ), } 
	 			} qw( upper_left upper_right lower_left lower_right )] );
			$globals->set_page_title( 'This Is The DemoFrameSet Demo' );
			$globals->set_page_style_code( 'BODY {background-color: white}' );
			$globals->set_page_body( "<H1>Your Browser Doesn't Do Frames</H1>" );
	 		last SWITCH;
	 	}
	 	
		$globals->http_window_target( $current_frame );
	
		if( $current_frame eq 'upper_left' ) {
			$globals->set_page_style_code( 'BODY {background-color: red}' );
			$globals->set_page_body( '<H1>The Upper-Left Red Corner</H1>' );
			last SWITCH;
		}
	
		if( $current_frame eq 'upper_right' ) {
			$globals->set_page_style_code( 'BODY {background-color: green}' );
			$globals->set_page_body( '<H1>The Upper-Right Green Corner</H1>' );
			last SWITCH;
		}
	
		if( $current_frame eq 'lower_left' ) {
			$globals->set_page_style_code( 'BODY {background-color: blue}' );
			$globals->set_page_body( '<H1>The Lower-Left Blue Corner</H1>' );
			last SWITCH;
		}
	
		if( $current_frame eq 'lower_right' ) {
			$globals->set_page_style_code( 'BODY {background-color: yellow}' );
			$globals->set_page_body( '<H1>The Lower-Right Yellow Corner</H1>' );
			last SWITCH;
		}
	
		$globals->set_page_body( 
			"<H1>Bad Frame Address of '$current_frame' - BAD</H1>" );
	}
}

1;
