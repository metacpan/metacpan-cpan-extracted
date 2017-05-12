# -*- Perl -*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1 + 2*8 + 2 + 1 + 2 +3;
BEGIN { use_ok('Convert::yEnc::Decoder') };

#########################

use strict;
use warnings;
use Config;
use IO::File;
require "t/utils.pl";

my $NTX = "t/ntx";
my $Dir = "t/Decoder.d";
mkdir $Dir;
my $NL  = whats_my_line();

Singles    ();
Name       ();
DecodeSTDIN();
OutDir     ();
Multiple   ();

sub Singles
{
    my $in = "$NTX/00000005.$NL";
    Single($in);
    open IN, $in or die "Can't open $in: $!\n";
    Single(\*IN);
    close IN;
}

sub Single
{
    my $in      = shift;
    my $out	= "$Dir/testfile.txt";
    my $exp 	= "$NTX/testfile.exp";
    my $decoder = new Convert::yEnc::Decoder $Dir;

    unlink $out;
    eval { $decoder->decode($in) };
    is($@, '', "decode $in");

    ok(CmpFiles($out, $exp), "cmp $out $exp");

    is($decoder->name, "testfile.txt", "name");
    is($decoder->file, $out          , "file");
    is($decoder->size, 584           , "size");

    my $ybegin = qq(=ybegin line=128 size=584 name=testfile.txt \n);
    my $yend   = qq(=yend size=584 crc32=ded29f4f \n);

    is($decoder->ybegin, $ybegin, "ybegin");
    is($decoder->ypart , undef  , "ypart" );
    is($decoder->yend  , $yend  , "yend"  );
}

sub Name
{
    my $in      = "$NTX/vole.$NL";
    my $out	= "$Dir/Who Stole My Vole";
    my $exp 	= "$NTX/testfile.exp";
    my $decoder = new Convert::yEnc::Decoder $Dir;

    unlink $out;
    eval { $decoder->decode($in) };
    is($@, '', "decode $in");

    ok(CmpFiles($out, $exp), "cmp $out $exp");
}

sub DecodeSTDIN
{
    my $in  = "$NTX/00000005.$NL";
    my $out = "$Dir/testfile.txt";
    my $exp = "$NTX/testfile.exp";

    unlink $out;
    system "$Config{perlpath} $Dir/decoder.pl $Dir < $in";

    ok(CmpFiles($out, $exp), "DeocdeSTDIN: cmp $out $exp");
}


sub OutDir
{
    my $in      = "$NTX/00000005.$NL";
    my $out	= "$Dir/testfile.txt";
    my $exp 	= "$NTX/testfile.exp";
    my $decoder = new Convert::yEnc::Decoder;
       $decoder->out_dir($Dir);

    unlink $out;
    eval { $decoder->decode($in) };
    is($@, '', "decode $in");

    ok(CmpFiles($out, $exp), "cmp $out $exp");
}


sub Multiple
{
    my $out 	= "$Dir/joystick.jpg";
    my $exp 	= "$NTX/joystick.exp";
    my $decoder = new Convert::yEnc::Decoder $Dir;

    unlink $out;
    Part($decoder, "00000020");
    Part($decoder, "00000021");

    ok(CmpFiles($out, $exp), "cmp $out $exp");
}

sub Part
{
    my($decoder, $base) = @_;
    my $in = "$NTX/$base.$NL";

    eval { $decoder->decode($in) };
    is($@, '', "decode $in");
}
