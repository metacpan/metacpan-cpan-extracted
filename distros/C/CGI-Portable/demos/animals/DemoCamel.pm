package DemoCamel;
use strict;
use warnings;
use CGI::Portable;

sub main {
	my ($class, $globals) = @_;
	my $users_choice = $globals->current_user_path_element();
	my $filename = $globals->pref( $users_choice );
	my $filepath = $globals->physical_filename( $filename );
	SWITCH: {
		$globals->add_no_error();
		open( FH, $filepath ) or do {
			$globals->add_virtual_filename_error( 'open', $filename );
			last SWITCH;
		};
		local $/ = undef;
		defined( my $file_content = <FH> ) or do {
			$globals->add_virtual_filename_error( "read from", $filename );
			last SWITCH;
		};
		close( FH ) or do {
			$globals->add_virtual_filename_error( "close", $filename );
			last SWITCH;
		};
		$globals->set_page_body( $file_content );
	}
	if( $globals->get_error() ) {
		$globals->append_page_body( 
			"Can't show requested screen: ".$globals->get_error() );
		$globals->add_no_error();
	}
}

1;
