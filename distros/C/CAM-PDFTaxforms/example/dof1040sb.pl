#!/usr/bin/perl

use CAM::PDFTaxforms;

my $doc = CAM::PDFTaxforms->new('./f1040sb.pdf');
my $page1 = $doc->getPageContent(1);
$doc->getFormFieldList();

my $fp = 'þÿform1[0].þÿPage1[0].þÿ';  #IRS USES LONG, CRAPPY HIGH-ASCII FIELD NAMES (ADOBE?)!
my (@entries, @amts);
open INDATA, './f1040sb_inputs.txt' or die "Could not open input data file ($!)!";
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
$doc->fillFormFields(
		$fp.'f1_01[0]' => 'DOE, JOHN Q.',  #NAME
		$fp.'f1_02[0]' => '123-45-6789',   #SSN
		$fp.'c1_1[1]' => 1,   #CHECK THE TWO "No" BOXES AT BOTTOM OF FORM:
		$fp.'c1_3[1]' => 1
);

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
$doc->fillFormFields($fp.'f1_99[0]' => $sum);

#WRITE THE NEWLY-ALTERED FORM TO A NEW FILE:
$doc->cleanoutput('./f1040sb_out.pdf');

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
