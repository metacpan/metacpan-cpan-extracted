#!perl

use Test::More tests => 7;
use Acme::AsciiArtinator;
use strict;
use warnings;

my $art = '
XXXXXXXXXXXXXXXXX
 XXXXXXXXXXXXXXX
  XXXXXXXXXXXXX
   XXXXXXXXXXX
    XXXXXXXXX
     XXXXXXX
      XXXXX
       XXX
        X';

my $code = '$_="rst";while(<>){print"Hello",", ","world!\n" if /st/;}';

my @input1 = ("hello world!\n",
	      "it's been nice knowing you\n",
	      "ist been nice\n");

my @output = asciiartinate( code => $code, art => $art,
			 test_argv1 => [], test_input1 => \@input1,
		         test_argv2 => ["hello"],  test_input2 => [] );

ok(defined $Acme::AsciiArtinator::TestOutput[1]);
ok(not defined $Acme::AsciiArtinator::TestOutput[0]);
ok(defined $Acme::AsciiArtinator::TestOutput[2]);
ok(length $Acme::AsciiArtinator::TestOutput[2] == 0);
ok($Acme::AsciiArtinator::TestOutput[1] eq "Hello, world!\n");
ok($Acme::AsciiArtinator::TestResult[1] eq "PASS");
ok($Acme::AsciiArtinator::TestResult[2] eq "PASS");
