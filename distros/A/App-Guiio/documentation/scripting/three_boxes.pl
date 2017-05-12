
use strict;
use warnings;
use lib qw(lib lib/stripes) ;

use App::Guiio;
use App::Guiio::stripes::editable_box2 ;

#-----------------------------------------------------------------------------

my $guiio = new App::Guiio() ;

#-----------------------------------------------------------------------------

my ($current_x, $current_y) = (0, 0) ;

for my $element_text (qw(box_1 box_2 box_3))
	{
	my $new_element = new App::Guiio::stripes::editable_box2
						({
						TEXT_ONLY => $element_text,
						TITLE => '',
						EDITABLE => 1,
						RESIZABLE => 1,
						}) ;
						
	$guiio->add_element_at($new_element, $current_x, $current_y) ;
	
	$current_x += $guiio->{COPY_OFFSET_X} ; 
	$current_y += $guiio->{COPY_OFFSET_Y} ;
	}
	
print $guiio->transform_elements_to_ascii_buffer() ;

