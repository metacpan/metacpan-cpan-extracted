#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $location->traverse(\&callback_function);
# ======================================================================

print "1..30\n";

$n = 1;

$loc1 = Data::Locations->new();

$loc1->print("[1]2>");
$loc2 = $loc1->new();
$loc1->print("<2[1]");

$loc2->print("[2]3>");
$loc3 = $loc2->new();
$loc2->print("<3[2]");

$loc3->print("[3]4>");
$loc4 = $loc3->new();
$loc3->print("<4[3]");

$loc4->print("[4]");

$loc1->print("[1]3>", $loc3, "<3[1]");
$loc1->print("[1]4>", $loc4, "<4[1]");

@text =
    (
        "[1]2>",
        "[2]3>",
        "[3]4>",
        "[4]",
        "<4[3]",
        "<3[2]",
        "<2[1]",
        "[1]3>",
        "[3]4>",
        "[4]",
        "<4[3]",
        "<3[1]",
        "[1]4>",
        "[4]",
        "<4[1]"
    );

$index = 0;

$loc1->traverse(\&compare_1);

if ($index == @text)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc = Data::Locations->new();

print $loc "<BEGIN>";
print $loc "";
print $loc "<MARKER>";
print $loc undef;
print $loc "<END>";

if (@{*{$loc}} == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc}}[0] eq "<BEGIN>")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined ${*{$loc}}[1])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc}}[1] eq "")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc}}[2] eq "<MARKER>")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! defined ${*{$loc}}[3])
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc}}[4] eq "<END>")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$index = 0;

$loc->traverse(\&compare_2);

if ($index == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

exit;

sub compare_1
{
    my($item) = @_;

    if ($item eq $text[$index++])
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub compare_2
{
    my($item) = @_;

    if    ($index == 0)
    {
        if ($item eq "<BEGIN>")
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
    elsif ($index == 1)
    {
        if (defined $item)
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
        if ($item eq '')
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
    elsif ($index == 2)
    {
        if ($item eq "<MARKER>")
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
    elsif ($index == 3)
    {
        if (! defined $item)
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
    elsif ($index == 4)
    {
        if ($item eq "<END>")
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
    else { }
    $index++;
}

__END__

