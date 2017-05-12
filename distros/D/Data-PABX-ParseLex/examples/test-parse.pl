#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Data::PABX::ParseLex;

# -----------------------------------------------

sub process
{
	my($parser, $input_file_name)	= @_;
	my($hash)						= $parser -> parse($input_file_name);

	print Data::Dumper -> Dump([$hash], ['PABX']);

}	# End of process.

# -----------------------------------------------

$Data::Dumper::Indent	= 1;
my($parser)				= Data::PABX::ParseLex -> new();

process($parser, 'pabx-a.txt');
process($parser, 'pabx-b.txt');
