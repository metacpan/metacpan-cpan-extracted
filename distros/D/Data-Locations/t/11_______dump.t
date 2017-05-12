#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $ok = $location->dump();
#   $ok = $location->dump($filename);
# ======================================================================

print "1..32\n";

$n = 1;

$self = $0;
$self =~ s!^.*[^0-9a-zA-Z_\.]!!;

$temp = $ENV{'TMP'} || $ENV{'TEMP'} || $ENV{'TMPDIR'} || $ENV{'TEMPDIR'} || '.';
$temp =~ s!/+$!!;

$file0 = "$temp/${self}_0.$$";
$file1 = "$temp/${self}_1.$$";
$file2 = "$temp/${self}_2.$$";
$file3 = "$temp/${self}_3.$$";
$file4 = "$temp/${self}_4.$$";

$ref4 = "[4]\n";
$ref3 = join('', ("[3]4>", $ref4, "<4[3]\n") );
$ref2 = join('', ("[2]3>", $ref3, "<3[2]\n") );
$ref1 = join('', ("[1]2>", $ref2, "<2[1]",
                  "[1]3>", $ref3, "<3[1]",
                  "[1]4>", $ref4, "<4[1]\n") );

##  Create scope for all locations:

{
    my($loc1,$loc2,$loc3,$loc4);

    unless (-f $file0)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (-f $file1)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (-f $file2)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (-f $file3)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (-f $file4)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $loc1 = Data::Locations->new(">-");

    $loc1->print("[1]2>");
    $loc2 = $loc1->new($file2);
    $loc1->print("<2[1]");

    $loc2->print("[2]3>");
    $loc3 = $loc2->new($file3);
    $loc2->print("<3[2]");

    $loc3->print("[3]4>");
    $loc4 = $loc3->new($file4);
    $loc3->print("<4[3]");

    $loc4->print("[4]");

    $loc1->print("[1]3>", $loc3, "<3[1]");
    $loc1->print("[1]4>", $loc4, "<4[1]");

    $loc1->println();
    $loc2->println();
    $loc3->println();
    $loc4->println();

    unless (-f $file0)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (-f $file1)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (-f $file2)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (-f $file3)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (-f $file4)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $loc1->dump($file0);
    $loc3->dump();
    $loc3->filename("");

    if (-f $file0)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    if (-s $file0 > 0)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (-f $file1)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (-f $file2)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    if (-f $file3)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    if (-s $file3 > 0)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (-f $file4)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (open(FILE, "<$file0"))
    {
        die "$self: can't read '$file0': \L$!\E\n";
    }
    $txt0 = join('', <FILE>);
    close(FILE);

    if ($txt0 eq $ref1)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (open(FILE, "<$file3"))
    {
        die "$self: can't read '$file3': \L$!\E\n";
    }
    $txt3 = join('', <FILE>);
    close(FILE);

    if ($txt3 eq $ref3)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unlink($file0);
    unlink($file3);

    unless (-f $file0)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (-f $file3)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    unless (open(TEMPHANDLE, ">&STDOUT"))
    {
        die "$self: can't save STDOUT in TEMPHANDLE: \L$!\E\n";
    }
    unless (open(STDOUT, ">$file1"))
    {
        die "$self: can't redirect STDOUT to '$file1': \L$!\E\n";
    }

}  ##  End of scope for all locations

unless (open(STDOUT, ">&TEMPHANDLE"))
{
    die "$self: can't restore STDOUT from TEMPHANDLE: \L$!\E\n";
}
undef *TEMPHANDLE; # silence warning "used only once"

unless (-f $file0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (-f $file1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (-s $file1 > 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (-f $file2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (-s $file2 > 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (-f $file3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (-f $file4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (-s $file4 > 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (open(FILE, "<$file1"))
{
    die "$self: can't read '$file1': \L$!\E\n";
}
$txt1 = join('', <FILE>);
close(FILE);

if ($txt1 eq $ref1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (open(FILE, "<$file2"))
{
    die "$self: can't read '$file2': \L$!\E\n";
}
$txt2 = join('', <FILE>);
close(FILE);

if ($txt2 eq $ref2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (open(FILE, "<$file4"))
{
    die "$self: can't read '$file4': \L$!\E\n";
}
$txt4 = join('', <FILE>);
close(FILE);

if ($txt4 eq $ref4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unlink($file1);
unlink($file2);
unlink($file4);

__END__

