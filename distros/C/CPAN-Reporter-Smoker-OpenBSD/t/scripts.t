use warnings;
use strict;
use Test::More;
use File::Spec;

opendir( my $dir, 'bin' ) or die "cannot read bin: $!";
my @programs = sort( readdir($dir) );
closedir($dir);

# removing dots...
for ( 1 .. 2 ) {
    shift(@programs);
}

plan tests => scalar(@programs);

for my $script (@programs) {
    is( system( $^X, '-cw', File::Spec->catfile( 'bin', $script ) ),
        0, "$script syntax is OK" );
}

