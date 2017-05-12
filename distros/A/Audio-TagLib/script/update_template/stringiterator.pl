#!/usr/bin/perl

use warnings;
use strict;
use Fcntl qw(O_CREAT O_WRONLY O_RDONLY O_TRUNC);

my $keyword = "USEWCHAR";

local $/ = "\n\n";
sysopen my $source, "xs/TITERATOR.xs", O_RDONLY or die "sysopen: $!";
sysopen my $target, "xs/stringiterator.xs", O_CREAT | O_WRONLY | O_TRUNC or die "sysopen: $!";

print $target "#define LONGMOVEMENT 1\n";
while(<$source>) {
	if(m/^\_NAMESPACE\_::data\(\)/mo){
		my @code = split /!!!!/;
		my ($code) = grep { m/$keyword/o } @code;
		$_ = $code[0]."//".$code."\n";
	}
	s/_NAMESPACE_/TagLib::String::Iterator/mg;
	#s/_T_/TagLib::APE::Item/mg;
	print $target $_;
}
print $target "\n#undef LONGMOVEMENT\n";
close $source or warn "close: $!";
close $target or die "close: $!";
