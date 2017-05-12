
use strict;
use warnings;

use lib qw(lib/stripes documentation/scripting/lib) ;

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

add_connection($guiio, $box1, $box2, 'down') ;
add_connection($guiio, $box2, $box3, ) ;
add_connection($guiio, $box3, $box1, 'up') ;
optimize_connections($guiio) ;

print $guiio->transform_elements_to_ascii_buffer() ;



