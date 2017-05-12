
use strict;
use warnings;
use lib qw(lib lib/stripes) ;

use App::Guiio ;
use App::Guiio::stripes::section_wirl_arrow;

#-----------------------------------------------------------------------------

my $guiio = new App::Guiio() ;

#-----------------------------------------------------------------------------

my $new_element = new App::Guiio::stripes::section_wirl_arrow
					({
					POINTS => [[5, 5, 'downright'], [10, 7, 'downright'], [7, 14, 'downleft'], ],
					DIRECTION => '',
					ALLOW_DIAGONAL_LINES => 0,
					EDITABLE => 1,
					RESIZABLE => 1,
					}) ;

$guiio->add_element_at($new_element, 5, 5) ;
	
print $guiio->transform_elements_to_ascii_buffer() ;

