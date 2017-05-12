use Test::Simple 'no_plan';

use strict;
use lib './lib';
use lib './t';
use Cwd;


$ENV{CGI_APP_RETURN_ONLY} = 1;
$CGI::Application::Plugin::Thumbnail::DEBUG = 1;
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








$ENV{DOCUMENT_ROOT} = cwd().'/t';

my $p = new PTest(
   PARAMS => { thumbnail_rel_dir => 'Thumbs', thumbnail_restriction => '200x200' }   
);

ok(   $p->set_abs_image(cwd().'/t/ayn_rand.jpg'),'set_abs_image()');

#print STDERR  $p->_img->abs_path."\n";

ok( $p->thumbnail_header_add, 'thumbnail header add');

my $rd = $p->_thumbnail_rel_dir;
ok($rd, " $rd");

my $ai = $p->abs_image;
ok($ai, "abs image is set to [$ai]");

ok($p->run,' run()');


ok( -d cwd().'/t/Thumbs',' Thumbs dir');
ok( -d cwd().'/t/Thumbs/200x200',' 200x200 dir');

ok( -f cwd().'/t/Thumbs/200x200/ayn_rand.jpg',' thumb file there');












