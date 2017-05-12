use Test::Simple 'no_plan';
use lib './lib';
use strict;
use Astroboy::AlbumFile;
$Astroboy::AlbumFile::DEBUG = 0;
use Smart::Comments '###';
use LEOCHARRE::Dir ':all';
use Cwd;

skipcond();

system('rm -rf ./t/music/dir2');

system('rm -rf ./t/userhome_tmp');
mkdir './t/userhome_tmp';

system('cp -R ./t/music/dir2_copy ./t/music/dir2');



$Astroboy::ABS_MUSIC = cwd().'/t/userhome_tmp/music';

my @mp3s = lsfa('./t/music/dir2');

for (@mp3s){
   _testone($_);
}

sub _testone {
   my $abs = shift;
   print STDERR "\n\n\nTESTING $abs\n==========\n\n";

   -f $abs or die("missing $abs");

   my $a = Astroboy::AlbumFile->new($abs);
   ok( $a, "got album file" ) or die;
   ok( $a->abs_music eq  cwd().'/t/userhome_tmp/music' );

   my $filename = $a->filename;
   ok $filename;
   my $suggested = $a->filename_suggested;
   ok $suggested;

   
   debug("filename:\n'$filename'\nsuggested:\n'$suggested'\n\n");

   my $rel_loc = $a->rel_loc_suggested;
   debug("rel loc:\n'$rel_loc'\n");

   my $rel_path_suggested = $a->rel_path_suggested;
   debug("rel path suggested:\n'$rel_path_suggested'\n");

   my $abs_path_suggested = $a->abs_path_suggested;
   debug("abs_path_suggested:\n'$abs_path_suggested'\n");

   my $exists = $a->abs_path_suggested_exists;
   debug("exists? $exists\n\n");

   my $loc = $a->abs_loc_suggested;
   debug(" ABS LOC SUGGESTED : '$loc'\n");

   my $loc_exists = $a->abs_loc_suggested_exists;
   debug("abs loc suggestion exists? $loc_exists");

   ok $a->refile, 'refile';

   

}


sub debug { print STDERR "@_"; 1 }
sub skipcond { 
   -d './t/music' and return 1;
   ok(1, 'skipped, missing ./t/music, must be distro');
   exit;
}

