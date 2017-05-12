package DemoAardvark;
use strict;
use warnings;
use CGI::Portable;

sub main {
	my ($class, $globals) = @_;
	my $users_choice = $globals->current_user_path_element();
	my $rh_screens = $globals->pref( 'screens' );
	
	if( my $rh_screen = $rh_screens->{$users_choice} ) {
		my $inner = $globals->make_new_context();
		$inner->inc_user_path_level();
		$inner->navigate_url_path( $users_choice );
		$inner->navigate_file_path( $rh_screen->{mod_subdir} );
		$inner->set_prefs( $rh_screen->{mod_prefs} );
		$inner->call_component( $rh_screen->{mod_name} );
		$globals->take_context_output( $inner );
	
	} else {
		$globals->set_page_body( "<P>Please choose a screen to view.</P>" );
		foreach my $key (keys %{$rh_screens}) {
			my $label = $rh_screens->{$key}->{link};
			my $url = $globals->url_as_string( $key );
			$globals->append_page_body( "<BR><A HREF=\"$url\">$label</A>" );
		}
	}
	
	$globals->page_title( $globals->pref( 'title' ) );
	$globals->prepend_page_body( "<H1>".$globals->page_title()."</H1>\n" );
	$globals->append_page_body( $globals->pref( 'credits' ) );
}

1;
