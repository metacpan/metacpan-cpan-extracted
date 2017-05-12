#!/usr/bin/perl

use warnings;
use strict;
use Fcntl qw(O_CREAT O_RDONLY O_WRONLY O_TRUNC);

sysopen my $source, "xs/TMAP.xs", O_RDONLY or die "sysopen: $!";
sysopen my $target, "xs/id3v2tagframelistmap.xs", O_CREAT | O_WRONLY | O_TRUNC or die "sysopen: $!";
print $target "#include \"id3v2tag.h\"\n";
while(<$source>) {
	s/_NAMESPACE_/TagLib::ID3v2::FrameListMap/g; 
	s/_KEY_/TagLib::ByteVector/g; 
	s/_T_/TagLib::ID3v2::FrameList/g;
	print $target $_;
}
close $source or warn "close: $!";
close $target or die "close: $!";
