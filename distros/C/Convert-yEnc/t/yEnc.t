# -*- Perl -*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1 + 2*2 + 3 + 8 + 2;
BEGIN { use_ok('Convert::yEnc') };

#########################

use strict;
use warnings;
use Convert::yEnc::RC;
require "t/utils.pl";

my $Dir = "t/yEnc.d";
my $NTX = "t/ntx";
my $NL  = whats_my_line();

Decodes();
Error  ();
RC     ();
Drop   ();


sub Decodes
{
    my $in = "$NTX/00000005.$NL";
    Decode($in);
    open IN, $in or die "Can't open $in: $!\n";
    Decode(\*IN);
    close IN;
}

sub Decode
{
    my $in = shift;
    my $rc = "$Dir/yencrc";
    unlink $rc;

    my $yEnc = new Convert::yEnc RC  => $rc,
                              out => $Dir;

    my $out = "$Dir/testfile.txt";
    my $exp = "$NTX/testfile.exp";

    unlink $out;
    my $ok = $yEnc->decode($in);
    ok($ok, "decode($in)");
    ok(CmpFiles($out, $exp), "DecodeFile: cmp $out $exp");
}


sub Error
{
    $ENV{HOME} = '' unless defined $ENV{HOME};	# for Win32
    my $yEnc = new Convert::yEnc;
    my $ok   = $yEnc->decode("no_such_file");
    isnt($ok, 1, "Error: ok");

    my $err;
    ($ok, $err) = $yEnc->decode("no_such_file");
    isnt($ok ,  1, "Error: ok" );
    isnt($err, "", "Error: err");
}


sub RC
{
    my $rc = "$Dir/yencrc";
    unlink $rc;

    my $tmp = "$Dir/tmp";
    my $out = "$Dir/out";
    mkdir $tmp;
    mkdir $out;

    {
	my $yEnc = new Convert::yEnc RC  => $rc, 
	                             out => $out,
	                             tmp => $tmp;

	for my $n (qw(05 20))
	{	       
	    my $ok = $yEnc->decode("$NTX/000000$n.$NL");
	    ok($ok, "RC: 000000$n");
	}    
    }

    ok(CmpFiles($rc, "$Dir/ntxrc"), "RC");

    {
	my $yEnc = new Convert::yEnc RC  => $rc, 
	                             out => $out,
	                             tmp => $tmp;

	my $ok = $yEnc->decode("$NTX/00000021.$NL");
	ok($ok, "RC: 00000021");
    }

    ok(-z $rc, "RC is empty");

    my $act = "$out/testfile.txt";
    my $exp = "$NTX/testfile.exp";
    ok(CmpFiles($act, $exp), "DecodeFile: cmp $act $exp");

       $act = "$out/joystick.jpg";
       $exp = "$NTX/joystick.exp";
    ok(CmpFiles($act, $exp), "DecodeFile: cmp $act $exp");

    opendir TMP, $tmp or die "Can't opendir $tmp: $!\n";
    my @tmp = grep { not m(^\.) } readdir(TMP);
    closedir TMP;
    is(@tmp, 0, "No temp files leftover");
}


package BitBucket;

use base qw(Convert::yEnc);

sub mkpath { undef }


package main;

sub Drop
{
    my $in = "$NTX/00000005.$NL";
    my $rc = "$Dir/yencrc";
    unlink $rc;

    my $yEnc = new BitBucket RC  => $rc,
                             out => $Dir;

    my $out = "$Dir/testfile.txt";

    unlink $out;
    my $ok = $yEnc->decode($in);
    ok($ok, "decode($in)");
    ok(not(defined(-e($out))), "Discard output file");
}
