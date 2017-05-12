#!/usr/bin/perl

use warnings;
use strict;
use Fcntl qw(O_CREAT O_RDONLY O_WRONLY O_TRUNC);

sysopen my $source, "xs/TMAP.xs", O_RDONLY or die "sysopen: $!";
sysopen my $target, "xs/apeitemlistmap.xs", O_CREAT | O_WRONLY | O_TRUNC or die "sysopen: $!";
while(<$source>) {
	s/_NAMESPACE_/TagLib::APE::ItemListMap/g; 
	s/_KEY_/TagLib::String/g; 
	s/_T_/TagLib::APE::Item/g;
	print $target $_;
}
close $source or warn "close: $!";
close $target or die "close: $!";
