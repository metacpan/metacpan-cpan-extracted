#!/usr/bin/perl
# A simple menu script
# By default the script uses ~/.con_menu.yml on unix type systems and <HOMEDIR>\_con_menu.yml
# on Windows type systems. If the files do not exist then you will be prompted to create an
# example version.

use strict;
use warnings;
use 5.10.0;
use File::HomeDir;
use File::Spec;
use Carp qw (croak);
use lib './lib/';
use App::ConMenu;
my $menu = App::ConMenu->new();
my $homeDir = File::HomeDir->my_home;
my $filePrefix = '.'; #.filename for unix type systems
if ($^O eq 'MSWin32') {
    $filePrefix = '_'; # _filename for windows.
}
my $fullFileName = File::Spec->catfile($homeDir, $filePrefix.'con_menu.yml') ;

#offer to create a default file
if (! -e $fullFileName ) {
   say 'The Yaml menu file does not exist in your home dir. ';
   say 'Would you like me to create it ? (Y/N)';
   my $selection = <>;
   chomp($selection);
   if (uc($selection) eq 'Y' ) {
       $menu->createDefaultFile($fullFileName);
       say ' File created at '.$fullFileName.' edit to add your entries';
   }
   exit;
}
$menu->{fileName} = $fullFileName;
$menu->loadMenuFile();
$menu->printMenu();
$menu->waitForInput();

