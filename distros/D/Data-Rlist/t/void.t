#!/usr/bin/perl
#
# void.t
#
# Test reading/writinge non-existing files and empty data.
#
# $Writestamp: 2008-07-17 17:20:44 eh2sper$
# $Compile: perl -M'constant standalone => 1' void.t$

use warnings;
use strict;
use constant;
use Test;
BEGIN { plan tests => 13 }
BEGIN { unshift @INC, '../lib' if $constant::declared{'main::standalone'} }

use Data::Rlist qw/:options/;

our $tempfile = "$0.tmp";

#########################

{
	open my $fh, ">$tempfile"; close $fh;	 # create file of zero size
	my $data = Data::Rlist::read($tempfile); # it shall be readable
	ok(not defined $data);					 # in form of undef
	unlink($tempfile);						 # erase it
	$data = eval { Data::Rlist::read($tempfile) }; # now trap die exception
	ok(not defined $data);						   # and get undef again

	ok((not defined ReadData(\" ")) && Data::Rlist::missing_input()); # empty input
	ok((not defined ReadData(\";")) && Data::Rlist::missing_input()); # dto.
	ok((not defined ReadData(\",")) && Data::Rlist::missing_input()); # dto.

	ok(ref(ReadData(\"()")) =~ /ARRAY/);
	ok(ref(ReadData(\"{}")) =~ /HASH/);
	ok(!Data::Rlist::missing_input());

	ok(exists ReadData(\"\"\"")->{''});
	ok(exists ReadData(\"0")->{0});
	ok(exists ReadData(\"\"0\"")->{0});
	ok(exists ReadData(\"-x ")->{-x});
	ok(ReadData(\"x = 5;")->{x} == 5);
}

unlink $tempfile;

### Local Variables:
### buffer-file-coding-system: iso-latin-1
### End:
