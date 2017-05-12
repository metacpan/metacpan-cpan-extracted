#!/usr/bin/perl
use strict;
use vars qw($VERSION);
use Getopt::Std::Strict 'dhv';
use LEOCHARRE::Dir ':all';
use LEOCHARRE::DEBUG;
use Cwd;
use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;
use File::Which 'which';

which($_) or die("missing $_?") for qw(faad lame);

init();



my @files = _argvfiles('m4a') or die("No files selected.");


for my $abs (@files){
   
   my $abs_to = $abs;
   $abs_to=~s/\.m4a/\.mp3/i or die;

   #`faad -o - "$abs" | lame - "$abs_to"`;

   `mplayer -ao pcm "$abs" -aofile "$abs.wav"`;
   $? and die(" $abs $?");

   `lame -h -b 192 "$abs.wav" "$abs_to"`;
   $? and die(" $abs $?");

   print "$abs_to\n";

   


}










exit;



sub usage {
   qq{$0 - convert m4a to mp3

We seek id3 tags artist, song, and album to copy over to the mp3 version.

OPTIONS

   -d       debug on
   -h       help
   -v       version and exit


AUTHOR

Leo Charre leocharre at cpan dot org

SEE ALSO



}}

sub init {
   $::DEBUG = 1 if $opt_d;
   $opt_h and print usage() and exit;
   $opt_v and print $VERSION and exit;

}



sub _argvfiles {
   my($ext)= shift;

   my @got;

   require Cwd;
   for (@ARGV){
      my $abs = Cwd::abs_path($_) or next;
      -f $abs or warn("not on disk $abs");
      if ($ext){
         $abs=~/\Q$ext\E$/ or warn("not '$ext', $abs") and next;
      }
      push @got, $abs;
   }
   @got or return;
   my $c = scalar @got;
   debug("Got @got");
   return @got;

}
