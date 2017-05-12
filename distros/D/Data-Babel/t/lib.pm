# add test paths to @INC: every directory from here to where the script lives
#   sorted from lowest (most specific) directory up
# usually just 't'. maybe 't/subdir', 't'. or even more

package t::lib;
use strict;
use FindBin;
use File::Spec::Functions qw(abs2rel splitdir catdir rel2abs);

sub paths {
  my $bin=abs2rel($FindBin::Bin);
  my @path=splitdir($bin);
  my $path=rel2abs shift @path;
  my @paths=$path;
  push(@paths,map {$path=catdir($path,$_)} @path);
  reverse @paths;
}

BEGIN {
  use lib paths();
}
1;
