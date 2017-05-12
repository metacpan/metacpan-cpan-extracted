use strict;
use warnings;
use Test::More;

use File::Find;

my @files = ();
sub wanted {
	push( @files, $File::Find::name ) if /\.pm\Z/;
}
find( \&wanted, ("lib") );

plan tests => scalar @files;

for (@files) {
	s/^.*\blib\b.//;
	s/.pm$//;
	s{[\\/]}{::}g;

	require_ok($_);
}

