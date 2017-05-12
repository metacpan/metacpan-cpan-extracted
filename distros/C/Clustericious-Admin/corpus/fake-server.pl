use strict;
use warnings;
use 5.010;
use Path::Class qw( file );
my $blib;
use if do { 
  $blib = file(__FILE__)->parent->parent->subdir('blib')->absolute;
  -d $blib;
}, 'blib';

unless(-d $blib)
{
  my $lib  = file(__FILE__)->parent->parent->subdir('lib')->absolute;
  unshift @INC, "$lib";
}

require App::clad;

exit App::clad->main(@ARGV);
