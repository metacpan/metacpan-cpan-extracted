#!/usr/bin/perl

use CAM::PDFTaxforms;

die "Could not open ./f1040sb_out.pdf ($!) -\n   (You must run dof1040sb.pl first!)"  unless (-e './f1040sb_out.pdf');
my $doc = CAM::PDFTaxforms->new('./f1040sb_out.pdf');
my $page1 = $doc->getPageContent(1);
$doc->getFormFieldList();

my $fp = 'þÿform1[0].þÿPage1[0].þÿ';  #IRS USES LONG, CRAPPY HIGH-ASCII FIELD NAMES (ADOBE?)!
my $fieldHash = $doc->getFieldValue($fp.'f1_49[0]', $fp.'f1_99[0]', $fp.'c1_1[1]');
print "Amt. to report on form 1040, line 2b: \$$$fieldHash{$fp.'f1_49[0]'}\n";
print "Amt. to report on form 1040, line 3b: \$$$fieldHash{$fp.'f1_99[0]'}\n";
print 'Box 7a is: '.($$fieldHash{$fp.'c1_1[1]'} ? 'CHECKED' : 'UNCHECKED')."\n";

exit(0);

__END__
