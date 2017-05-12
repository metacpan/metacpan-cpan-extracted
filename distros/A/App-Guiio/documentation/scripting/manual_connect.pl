
use strict;
use warnings;

use lib qw(documentation/scripting/lib) ;

use App::Guiio ;
use scripting_lib ;

#-----------------------------------------------------------------------------

my $guiio = new App::Guiio() ;
my ($command_line_switch_parse_ok, $command_line_parse_message, $guiio_config)
	= $guiio->ParseSwitches([@ARGV], 0) ;

die "Error: '$command_line_parse_message'!" unless $command_line_switch_parse_ok ;

$guiio->setup($guiio_config->{SETUP_INI_FILE}, $guiio_config->{SETUP_PATH}) ;

#-----------------------------------------------------------------------------

my $box1 = new_box(TEXT_ONLY =>'box1') ;
$guiio->add_element_at($box1, 0, 2) ;

my $box2 = new_box(TEXT_ONLY =>'box2') ;
$guiio->add_element_at($box2, 20, 10) ;

my $box3 = new_box(TEXT_ONLY =>'box3') ;
$guiio->add_element_at($box3, 40, 5) ;

my $arrow = new_wirl_arrow () ;
$guiio->add_element_at($arrow, 0,0) ;

my $start_connection = move_named_connector($arrow, 'startsection_0', $box1, 'bottom_center');
my $end_connection = move_named_connector($arrow, 'endsection_0', $box2, 'bottom_center') ;

die "missing connection!" unless defined $start_connection && defined $end_connection ;

$guiio->add_connections($start_connection, $end_connection) ;
get_canonizer()->([$start_connection, $end_connection]) ;

print $guiio->transform_elements_to_ascii_buffer() ;

#-----------------------------------------------------------------------------------------------------------

