package  # hide from CPAN
	StubTestImage;
use Path::Class;

# stub this at install time
*Data::TestImage::get_dist_dir = sub {
	dir( 'share' );
};

1;
