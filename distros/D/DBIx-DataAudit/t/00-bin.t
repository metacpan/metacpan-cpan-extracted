use strict;
use Test::More;
use File::Find;
use File::Spec;

opendir BIN,'bin'
    or die "Couldn't read directory 'bin': $!";

my @bin = grep {-f} map { File::Spec->catfile('bin',$_) } readdir BIN;

plan tests => scalar @bin;

for my $file (@bin) {
    ok system($^X,'-c',$file) == 0, "$file compiles";
};
