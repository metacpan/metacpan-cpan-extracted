#!/usr/bin/perl -w

use warnings;
use strict;
use Carp;

$SIG{__WARN__} = $SIG{__DIE__} = \&Carp::confess;

use Test::More;

# Begin testing

BEGIN {
	plan tests => 7;
	use_ok('CAM::PDFTaxforms');
}

diag( "Verifying filled out IRS form from previous test..." );

# Utility routines for diagnosing test failures
sub clearerr { $CAM::PDFTaxforms::errstr = ''; }
sub checkerr { if ($CAM::PDFTaxforms::errstr) { diag($CAM::PDFTaxforms::errstr); clearerr(); } }

clearerr();
ok(-e 't/f1040sb_out.pdf', "See if Tax form successfully created by prev. test?");
my $doc = CAM::PDFTaxforms->new('t/f1040sb_out.pdf');
ok($doc, 'open IRS schedule B tax form');
checkerr();
my $page1 = $doc->getPageContent(1);
ok($page1, 'getting form content');
checkerr();
$doc->getFormFieldList();
checkerr();

my $fp = 'þÿform1[0].þÿPage1[0].þÿ';  #IRS USES LONG, CRAPPY HIGH-ASCII FIELD NAMES (ADOBE?)!
my $fieldHash = $doc->getFieldValue($fp.'f1_49[0]', $fp.'f1_99[0]', $fp.'c1_1[1]');
ok($$fieldHash{$fp.'f1_49[0]'} == 20, "Amt. to report on form 1040, line 2b: \$$$fieldHash{$fp.'f1_49[0]'} (should be 20)!");
ok($$fieldHash{$fp.'f1_99[0]'} eq '8,407', "Amt. to report on form 1040, line 3b: \$$$fieldHash{$fp.'f1_99[0]'} (should be 8,407)!\n");
ok($$fieldHash{$fp.'c1_1[1]'}, 'Box 7a is: '.($$fieldHash{$fp.'c1_1[1]'} ? 'CHECKED' : 'UNCHECKED')." (should be CHECKED)!");

exit(0);

__END__
