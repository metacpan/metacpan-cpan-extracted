#!/usr/bin/perl

my $dir = '..';

while (<$dir/OpenCV-1.*>) {
    next unless /OpenCV-(\d+\.\d+\.\d+)$/;
    my $version = $1;
    my $flags = $flags{$version} || $flags_default;
    print (
	"mkdir ./cv$$ ./cv$$/opencv\n",
	"cp -r $_/*/include/ $_/otherlibs/*/ ./cv$$/opencv\n",
	"./tools/dumpconst.pl ./cv$$/ -v ",
	">fallback/Constant.pm-$version\n",
	"rm -rf ./cv$$\n",
	);
}

while (<$dir/OpenCV-2.*>) {
    next unless /OpenCV-(\d+\.\d+\.\d+)$/;
    my $version = $1;
    my $flags = $flags{$version} || $flags_default;
    print ("./tools/dumpconst.pl $_/include/ $_/modules/*/include/ -v ",
	">fallback/Constant.pm-$version\n");
}
