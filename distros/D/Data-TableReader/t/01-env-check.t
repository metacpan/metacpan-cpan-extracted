#! /usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

diag "Checking optional modules";
for (qw(
	Text::CSV
	Text::CSV_XS
	Archive::Zip
	Spreadsheet::XLSX
	Spreadsheet::ParseXLSX
	Spreadsheet::ParseExcel
	Type::Tiny
	Types::Standard
)) {
	if (eval "require $_") {
		diag "Have $_ ".$_->VERSION;
	} else {
		diag "No   $_";
	}
}

pass('This is just for CPAN testers reports');
