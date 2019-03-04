#!perl

# $Id: Lexer-comments.t,v 1.6 2010/11/21 16:48:35 Paulo Exp $

use strict;
use warnings;

use_ok 'Asm::Preproc';
use_ok 'Asm::Preproc::Line';

our $pp;

#------------------------------------------------------------------------------
# Utilities
sub test_getline { 
	my($text, $file, $line_nr) = @_;
	my $caller_line_nr = (caller)[2];
	my $test_name = "[line $caller_line_nr]";
		
		my $line = $pp->getline;

		isa_ok $line, 'Asm::Preproc::Line';
		
	# convert path separators to Unix-type
	if ($line) {
		my $line_file = $line->file;
		$line_file =~ s/\\/\//g;
		$line->file($line_file);
	}
		
		is_deeply $line, 	
				Asm::Preproc::Line->new($text, $file, $line_nr),
				"$test_name line";
}

sub test_eof {
	my $caller_line_nr = (caller)[2];
	my $test_name = "[line $caller_line_nr]";
	
	for (1..2) {
		my $line = $pp->getline;
		is $line, undef, "$test_name eof";
	}
}

1;
