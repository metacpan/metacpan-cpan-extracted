use strict;
use warnings;
use File::Path qw( rmtree );
use File::Spec;

my $dir = File::Spec->catdir( '_alien' );
rmtree($dir, 0, 1) if -d $dir;
