use strict;
use warnings;
use Archive::Libarchive::Extract;

my $extract = Archive::Libarchive::Extract->new( filename => 'archive.tar' );
$extract->extract;
