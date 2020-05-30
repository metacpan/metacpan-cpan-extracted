use strict;
use File::Find;
use FindBin ();
use Test::More;

my @files;
find( sub { push @files, $File::Find::name if /\.p(?:m|od)$/ }, "$FindBin::Bin/.." );

plan tests => scalar @files;

SKIP: {
    eval { require Test::Pod; import Test::Pod; };
    skip "Test::Pod not available", scalar @files if $@;
    if ( $Test::Pod::VERSION >= 0.95 ) {
        pod_file_ok($_) for @files;
    }
    else {
        pod_ok($_) for @files;
    }
}


unless($ENV{'HARNESS_ACTIVE'}) {
	#require Data::Dumper; Data::Dumper->import('Dumper'); local $Data::Dumper::Terse = 1;
	#print 'Files: ' . Dumper(\@files);
}
