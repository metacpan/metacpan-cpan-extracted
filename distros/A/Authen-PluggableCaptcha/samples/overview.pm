use warnings;
use strict;

use lib qw( ../.. );

use Authen::PluggableCaptcha;

sub print_line { print "\n=================================="; };

&print_line();
	print "\n testing GENERATE a new key... ";
my 	$captcha= Authen::PluggableCaptcha->new( 
	type=>'new' , 
	seed=> 'a' , 
	site_secret=> 'z' 
);
my 	$captcha_publickey= $captcha->get_publickey();
	printf "\nnew->'%s'\n" , $captcha_publickey;

my $as_string;

&print_line();
	print "\n testing an EXISTING - new JPEG... ";
	print "\n\t\t Authen::PluggableCaptcha->new( type=> 'existing' , publickey=> '$captcha_publickey', seed=> 'a' , site_secret=> 'z' );";
	print "\n";
$captcha= Authen::PluggableCaptcha->new( 
	type=> 'existing' , 
	publickey=> $captcha_publickey, 
	seed=> 'a' , 
	site_secret=> 'z' 
);
	print "\n\t\t captcha->render( challenge_class=> 'TypeString', render_class=>'Authen::PluggableCaptcha::Render::Img::Imager' ,  format=>'jpeg' )";
$as_string= $captcha->render( 
	challenge_class=> 'Authen::PluggableCaptcha::Challenge::TypeString', 
	render_class=>'Authen::PluggableCaptcha::Render::Image::Imager' ,  
	font_filename=> '/usr/X11R6/lib/X11/fonts/TTF/VeraMoIt.ttf',
	format=>'jpeg' 
);
open(WRITE, ">overview/test.jpg");
print WRITE $as_string;
close(WRITE);
print $captcha->__dict__();

&print_line();
	print "\n testing an EXISTING - new Text... ";
	print "\n\t\t Authen::PluggableCaptcha->new( type=> 'existing' , publickey=> '$captcha_publickey', seed=> 'a' , site_secret=> 'z' );";
	print "\n";
$captcha= Authen::PluggableCaptcha->new( 
	type=> 'existing' , 
	publickey=> $captcha_publickey, 
	seed=> 'a' , 
	site_secret=> 'z' 
);
	print "\n\t\t captcha->render( challenge_class=> 'DoMath', render_class=>'Text::HTML' )";
$as_string= $captcha->render( 
	challenge_class=> 'Authen::PluggableCaptcha::Challenge::DoMath', 
	render_class=>'Authen::PluggableCaptcha::Render::Text::HTML' 
);
open(WRITE, ">overview/test.html");
print WRITE $as_string;
close(WRITE);
print $captcha->__dict__();

&print_line();
	print "\n testing an EXISTING - VALIDATE ";
	print "\n\t\t Authen::PluggableCaptcha->new( type=> 'existing' , publickey=> '$captcha_publickey', seed=> 'a' , site_secret=> 'z' );";
	print "\n";
$captcha= Authen::PluggableCaptcha->new( 
	type=> 'existing' , 
	publickey=> $captcha_publickey, 
	seed=> 'a' , 
	site_secret=> 'z' 
);

# run the validation 1x through, just so we get the vars set up and can pull the correct_response
my 	$crap= $captcha->validate_response( challenge_class=> 'Authen::PluggableCaptcha::Challenge::TypeString' , user_response=>'a' ) ? "yes" : "no" ;
my 	$success= $captcha->validate_response( challenge_class=> 'Authen::PluggableCaptcha::Challenge::TypeString' , user_response=>$captcha->{'__Challenge'}{'Authen::PluggableCaptcha::Challenge::TypeString'}{'correct_response'} ) ? "yes" : "no" ;

	print "\n\t ---------- \n\t did we validate_response? $success ";
	print "\n";