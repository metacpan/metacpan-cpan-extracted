#!/usr/bin/perl

use warnings;
use strict;
use Fcntl qw(O_CREAT O_RDONLY O_WRONLY O_TRUNC);

sysopen my $source, "xs/TLIST.xs", O_RDONLY or die "sysopen: $!";
sysopen my $target, "xs/id3v2tagframelist.xs", O_CREAT | O_WRONLY | O_TRUNC or die "sysopen: $!";
print $target "#include \"id3v2tag.h\"\n";
while(<$source>) {
	s/_NAMESPACE_/TagLib::ID3v2::FrameList/g; 
	s/_T_/TagLib::ID3v2::Frame/g;
	print $target $_;
}
close $source or warn "close: $!";
close $target or die "close: $!";
