package DemoDrawImage;
use strict;
use warnings;
use CGI::Portable;

my $PIC_SUBPATH = 'thepic';

sub main {
	my ($class, $globals) = @_;

	if( $globals->current_user_path_element() eq $PIC_SUBPATH ) {
		require GD;

		# create a new image
		my $im = new GD::Image(100,100);

		# allocate some colors
		my $white = $im->colorAllocate(255,255,255);
		my $black = $im->colorAllocate(0,0,0);   
		my $red = $im->colorAllocate(255,0,0);  
		my $blue = $im->colorAllocate(0,0,255);

		# make the background transparent and interlaced
		$im->transparent($white);
		$im->interlaced('true');

		# Put a black frame around the picture
		$im->rectangle(0,0,99,99,$black);

		# Draw a blue oval
		$im->arc(50,50,95,75,0,360,$blue);

		# And fill it with red
		$im->fill(50,50,$red);

		# make sure we are writing to a binary stream
		$globals->http_body_is_binary( 1 );

		# Convert the image to PNG and print it on standard output
		$globals->http_content_type( 'image/png' );
		$globals->http_body( $im->png() );

	} else {
		my $pic_url = $globals->url_as_string( $PIC_SUBPATH );
	
		$globals->page_title( "The GD Synopsis PNG" );
	
		$globals->set_page_body( <<__endquote );
<H1>The GD Synopsis PNG</H1>

<P>Here is the sample image from the Synopsis of GD.pm.  You need to have the 
GD module installed to see it propertly, or you'll get a broken image link.  
The image is in PNG format.</P>

<IMG SRC="$pic_url" ALT="The PNG I Made">

<P>Click <A HREF="$pic_url">here</A> to see the image by itself (not in an HTML 
page) or to read any error page that may have been made.</P>
__endquote
	}
}

1;
