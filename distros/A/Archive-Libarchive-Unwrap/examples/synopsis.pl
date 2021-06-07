use strict;
use warnings;
use Archive::Libarchive::Unwrap;

my $uw = Archive::Libarchive::Unwrap->new( filename => 'hello.txt.uu' );
print $uw->unwrap;
