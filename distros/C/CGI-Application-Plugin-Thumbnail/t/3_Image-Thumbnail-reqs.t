use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();







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
   ok( scalar @pms, "have GD, Image::Magick or Imager installed");


















sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}


