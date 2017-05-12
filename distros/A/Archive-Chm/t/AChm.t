# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AChm.t'

#########################

use Test::More tests => 8;
BEGIN { use_ok('Archive::Chm') };


#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$chm = Archive::Chm->new('TestPrj.chm');
isa_ok($chm, 'Archive::Chm');

$chm->set_overwrite(1);
$chm->set_verbose(0);

#test the file enumeration capabilities
$filename = "base.lst";
for ($i = 2; $i > 0; $i--) {
	
	$filename = "all.lst" if ($i == 1);
	$result = $chm->enum_files("temp.lst", $i);
	#see if we returned ok from the enum_files function
	ok($result == 0, "Enumeration interface.") or
		diag($result == 2 ? "Can't create/override output file. Maybe check permissions?" :
							"Unkown error in enumeration API. Try reinstalling chmlib.");
		
	open(TEMP, "<", "temp.lst") or 
		die "Error opening 'temp.lst' from test script: $!\n";
	open(IN, "<", "$filename") or
		die "Error opening '$filename' from test script: $!\n" . 
			"Maybe the distribution is not complete.\n";
	$ok = 1;
	while (<IN>) {
		$line = <TEMP>;
		if ($line ne $_) {
			$ok = 0;
			last;
		}
	}
	ok($ok, ($i == 2 ? "Base " : "All ") . "files enumeration corectness.");
	close TEMP;
	close IN;
}


#test the extracting capabilities
ok($chm->extract_all("./out") == 0, "Extraction interface.") ||
	diag("Unkown error in extraction API. Try reinstalling chmlib.");
open(IN, "<", "temp.lst") or
	die "Error opening 'temp.lst' from test script: $!\n";
open(LEN, "<", "lengths.txt") or
	die "Error opening 'lengths.txt' from test script: $!\n";
chomp($line = <LEN>); chop($line);
close LEN;
@sizes = split(/ /, $line);
$i = $j = 0; $ok = 1;
while (<IN>) {
	chomp; $i++;
	next if /:/; 
	s#^[^/]*/##;
	next if (/^[:#\$]/ || $i < 6);
	unless (-e "./out/$_") {
		$ok = 0; 
		$message = "$_ was not extracted.";
		last;
	}
	$size = -s "./out/$_";
	if ($size != $sizes[$j]) {
		$ok = 0;
		$message = "File sizes incorrect.";
		last;
	}
	$j++;
}
ok($ok == 1, "Extraction corectness") or diag($message);
close IN;
unlink("temp.lst") or
	die "Error deleting 'temp.lst' in test script: $!\n";
`rm -rf ./out`;