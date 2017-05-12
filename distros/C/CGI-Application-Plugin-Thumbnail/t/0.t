use Test::Simple 'no_plan';
use strict;
use lib './lib';
use lib './t';
use Cwd;
use PTest;


BEGIN {
   ok(1);
   my @pms; # which work ?
   for my $pm ( qw/GD Image::Magick Imager BoguZNonseze::Module::herew2123523::indeed/ ){
      
      my $r ;
      $r = eval("require $pm;");
      $r||=0;
      
      warn("  - require $pm: $r\n");
      $r or next;
      push @pms, $pm;   
   }
   warn "WORKING MODULES: @pms\n\n";
   scalar @pms or warn("You dont have GD, Image::Magick or Imager installed, skipping.") and exit;

}







my $_part =0;



$ENV{CGI_APP_RETURN_ONLY} = 1;

$CGI::Application::Plugin::Thumbnail::DEBUG = 1;

sub ok_part { printf STDERR "\n====================\n PART %s %s\n====================\n\n", $_part++, "@_" }



ok_part("MAKE sure Image::Thumbnail will really work.\n
I am getting fail reports because Image::Thumbnail is crashing when it does not find Image::Magick");
use Image::Thumbnail;
my $abs_img = cwd().'/t/ayn_rand.jpg';
my $abs_img_out = cwd().'/t/ayn_rand_thumb.jpg';
unlink $abs_img_out;

-f $abs_img or die("missing files, check your distro.");
my $__t = new Image::Thumbnail(
   size => 50,
   create => 1,
   input => $abs_img,
   outputpath => $abs_img_out,
);
ok( $__t->create );
ok( -f $abs_img_out, "Image::Thumbnail works" ) or die("Image::Thumbnail fails");



ok_part("TEST BEGINS..");

$ENV{DOCUMENT_ROOT} = cwd().'/t';

my $p = new PTest;

ok(   $p->set_abs_image(cwd().'/t/ayn_rand.jpg'),'set_abs_image()');

#print STDERR  $p->_img->abs_path."\n";

ok( $p->thumbnail_header_add, 'thumbnai lheader add');

my $ai = $p->abs_image;
ok($ai, "abs image is set to [$ai]");

ok($p->run,' run()');

ok_part("TEST ON DISK");

ok( -d cwd().'/t/.thumbnails',' .thumbnails dir');

ok( -f cwd().'/t/.thumbnails/100x100/ayn_rand.jpg',' thumb file there');












