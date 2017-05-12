#!/usr/bin/perl

use warnings;
use strict;
use Fcntl qw(O_CREAT O_WRONLY O_RDONLY O_TRUNC);

my $keyword = "USEPAIR";

local $/ = "\n\n";
sysopen my $source, "xs/TITERATOR.xs", O_RDONLY or die "sysopen: $!";
sysopen my $target, "xs/oggfieldlistmapiterator.xs", O_CREAT | O_WRONLY | O_TRUNC or die "sysopen: $!";

#print $target "#define MOREMETHODS 1\n";
print $target "#include \"xiphcomment.h\"\n";
while(<$source>) {
	if(m/^\_NAMESPACE\_::data\(\)/mo){
		my @code = split /!!!!/;
		my ($code) = grep { m/$keyword/o } @code;
		$_ = $code[0]."//".$code."\n";
	}
	s/_NAMESPACE_/TagLib::Ogg::FieldListMap::Iterator/mg;
	s/_T_/TagLib::StringList/mg;
	print $target $_;
}

close $source or warn "close: $!";
close $target or die "close: $!";
