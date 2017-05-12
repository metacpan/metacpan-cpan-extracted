use strict;
use warnings;
use File::Path qw( rmtree );

# if the [GatherDir] plugin accidentally
# gathers the msys32 / msys64 folders

chdir('share') || die;

my $dh;
opendir($dh, '.') || die;

foreach my $name (readdir $dh)
{
  next unless $name =~ /^msys(64|32)/;
  if(-d $name)
  {
    rmtree($name, 0, 0);
  }
}

closedir $dh;

