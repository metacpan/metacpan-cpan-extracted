#!/usr/bin/perl -w

use warnings;
use strict;
use Carp;

$SIG{__WARN__} = $SIG{__DIE__} = \&Carp::confess;

use Test::More;

# Begin testing

BEGIN {
	plan tests => 12;
	use_ok('CAM::PDFTaxforms');
}

diag( "Testing filling in IRS Schedule B tax form..." );

# Utility routines for diagnosing test failures
sub clearerr { $CAM::PDFTaxforms::errstr = ''; }
sub checkerr { if ($CAM::PDFTaxforms::errstr) { diag($CAM::PDFTaxforms::errstr); clearerr(); } }

clearerr();
my $doc = CAM::PDFTaxforms->new('t/f1040sb.pdf');
ok($doc, 'open IRS schedule B tax form');
checkerr();
my $page1 = $doc->getPageContent(1);
ok($page1, 'getting form content');
checkerr();
$doc->getFormFieldList();
checkerr();

my $fp = 'þÿform1[0].þÿPage1[0].þÿ';  #IRS USES LONG, CRAPPY HIGH-ASCII FIELD NAMES (ADOBE?)!
my (@entries, @amts);
open INDATA, 't/f1040sb_inputs.txt' or die "Could not open input data file ($!)!";
while (<INDATA>) {
	chomp;
	next  if (/^\s*\#/o);
	next  unless (/^\d+\,[^\,]+\,\d+$/o);
	my ($inkey, $payor, $amt) = split /\,/o;
	--$inkey;
	push @{$entries[$inkey]}, $payor;
	push @{$amts[$inkey]}, $amt;
}

#UPDATE THE VALUES OF ONE OF THE FIELDS AND A COUPLE OF THE CHECKBOXES:
#$doc->fillFormFields('f1_02(0)' => 'Ajram Graphix');
{
	my $fieldsfilled = $doc->fillFormFields(
			$fp.'f1_01[0]' => 'DOE, JOHN Q.',  #NAME
			$fp.'f1_02[0]' => '123-45-6789',   #SSN
			$fp.'c1_1[1]' => 1,   #CHECK THE TWO "No" BOXES AT BOTTOM OF FORM:
			$fp.'c1_3[1]' => 1
	);
	checkerr();
	ok($fieldsfilled == 4, "Filled in $fieldsfilled initial fields, (should be 4)!");

	my $sum = 0;
	for (my $i=3; $i<=42; $i+=3) {   #WRITE OUT AND SUM ALL THE INTEREST ACCOUNTS:
		last  if ($#{$entries[0]} < 0);
		$sum += $amts[0]->[0];
		$doc->fillFormFields(
				$fp.'f1_'.sprintf('%2.2d', $i).'[0]' => shift(@{$entries[0]}),
				$fp.'f1_'.sprintf('%2.2d', ($i+1)).'[0]' => &commatize(shift(@{$amts[0]}))
		);
	}
	$sum = &commatize($sum);
	$doc->fillFormFields(
			$fp.'f1_45[0]' => $sum,
			$fp.'f1_49[0]' => $sum
	);

	$sum = 0;
	for (my $i=51; $i<=96; $i+=3) {   #WRITE OUT AND SUM ALL THE DIVIDEND ACCOUNTS:
		last  if ($#{$entries[1]} < 0);
		$sum += $amts[1]->[0];
		$doc->fillFormFields(
				$fp.'f1_'.$i.'[0]' => shift(@{$entries[1]}),
				$fp.'f1_'.($i+1).'[0]' => &commatize(shift(@{$amts[1]}))
		);
	}
	$sum = &commatize($sum);
	ok($sum eq '8,407', "Total is $sum (should be 8,407)!");
	$doc->fillFormFields($fp.'f1_99[0]' => $sum);

#WRITE THE NEWLY-ALTERED FORM TO A NEW FILE:
	$doc->cleanoutput('t/f1040sb_out.pdf');
	checkerr();
}

#NOW VERIFY THAT WE CREATED THE NEW FILLED-OUT PDF FILE CORRECTLY:

diag( "Verifying filled out IRS form from previous test..." );

ok(-e 't/f1040sb_out.pdf', "See if Tax form successfully created by prev. test?");
{
	my $newdoc = CAM::PDFTaxforms->new('t/f1040sb_out.pdf');
	ok($newdoc, 'Open IRS schedule B tax form');
	checkerr();
	my $newpage1 = $newdoc->getPageContent(1);
	ok($newpage1, 'Getting form content');
	checkerr();
	$newdoc->getFormFieldList();
	checkerr();

	my @fieldData = $newdoc->getFieldValue($fp.'f1_49[0]', $fp.'f1_99[0]', $fp.'c1_1[1]');
	ok($#fieldData == 5, 'Returned data for '.scalar(@fieldData).' fields, should be 6!');
	ok($fieldData[1] == 20, "Amt. to report on form 1040, line 2b: \$$fieldData[1] (should be 20)!");
	ok($fieldData[3] eq '8,407', "Amt. to report on form 1040, line 3b: \$$fieldData[3] (should be 8,407)!\n");
	ok($fieldData[5], 'Box 7a is: '.($fieldData[5] ? 'CHECKED' : 'UNCHECKED')." (should be CHECKED)!");

	#DISPLAY THE FILLED-OUT FORM USING EVINCE (ONLY IF WE'RE ABLE!):
	unless ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING}) {
		eval { system('evince t/f1040sb_out.pdf'); };
	}
}

exit(0);

sub commatize
{
	my $val = shift;
	my $decPlaces = shift;
	unless (defined $decPlaces) {
		my $decPart = '';
		$decPart = $1  if ($val =~ /\.(\d+)/o);
		$decPlaces = length($decPart) || '0';
	}

	$val = sprintf("%.${decPlaces}f",$val);
	$val =~ s/(\d)(\d\d\d)$/$1,$2/;
	$val =~ s/(\d)(\d\d\d),/$1,$2,/g;
	$val = '(' . $val . ')'  if ($val =~ s/^\-//);
	return $val;
}

__END__
