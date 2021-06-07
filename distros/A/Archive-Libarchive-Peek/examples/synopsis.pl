use strict;
use warnings;
use Archive::Libarchive::Peek;
my $peek = Archive::Libarchive::Peek->new( filename => 'archive.tar' );
my @files = $peek->files();
my $contents = $peek->file('README.txt')
