#!/usr/bin/perl

use warnings;
use strict;
use Fcntl qw(O_CREAT O_RDONLY O_WRONLY O_TRUNC);

sysopen my $source, "xs/TMAP.xs", O_RDONLY or die "sysopen: $!";
sysopen my $target, "xs/oggfieldlistmap.xs", O_CREAT | O_WRONLY | O_TRUNC or die "sysopen: $!";
print $target "#include \"xiphcomment.h\"\n";
while(<$source>) {
	s/_NAMESPACE_/TagLib::Ogg::FieldListMap/g; 
	s/_KEY_/TagLib::String/g; 
	s/_T_/TagLib::StringList/g;
	print $target $_;
}
close $source or warn "close: $!";
close $target or die "close: $!";
