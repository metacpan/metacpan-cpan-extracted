
use strict;
use warnings;
use lib qw(lib lib/stripes) ;
use Data::TreeDumper ;

use App::Guiio ;
use App::Guiio::stripes::if_box ;

#-----------------------------------------------------------------------------

my $guiio = new App::Guiio() ;

#-----------------------------------------------------------------------------

my @text =
	(
	'a == 1235',
	'b < 0',
	'b > 125',
	'very long',
	'&& $x >= $y_123',
	'c eq 35',
	' $a ~= /^$/',
	) ;

my $box_index = 0 ;
my $next_line = 0 ;

for (1 .. 7)
	{
	my $text  = '' ;
	$text  .= $text[rand(@text)] . "\n" for (1 .. $box_index) ;
	
	my $if_box = new App::Guiio::stripes::if_box
					({
					TEXT_ONLY => $text,
					EDITABLE => 1,
					RESIZABLE => 1,
					}) ;
	@$if_box{'X', 'Y'} = (0, $next_line) ;
	
	$guiio->add_elements($if_box) ;
	
	my ($w, $h) = $if_box->get_size() ;
	$next_line += $h + 1 ;
	
	$box_index++ ;
	}
	
print $guiio->transform_elements_to_ascii_buffer() ;

