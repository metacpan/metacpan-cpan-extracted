#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $item = $location->read();
#   $item = <$location>;
#   @list = $location->read();
#   @list = <$location>;
# ======================================================================

print "1..124\n";

$n = 1;

$loc1 = Data::Locations->new();

$loc1->print("[1]>");
$loc2 = $loc1->new();
$loc1->print("[1]");

$loc2->print("[2]>");
$loc3 = $loc2->new();
$loc2->print("<[2]");

$loc3->print("[3]");

$loc1->print($loc3, "<[1]");

if (! exists ${*{$loc1}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str = $loc1->read();

if ($str eq '[1]>')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (exists ${*{$loc1}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$stack = ${*{$loc1}}{'stack'};

if (ref($stack))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (ref($stack) eq 'ARRAY')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$stack} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[0]}[0] == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$name = ${${$stack}[0]}[1];

if ($name =~ /^LOCATION\d+$/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (exists $Data::Locations::{$name})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${*{$Data::Locations::{$name}}} eq $loc1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str = <$loc1>;

if ($str eq '[2]>')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$stack} == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[0]}[0] == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$Data::Locations::{${${$stack}[0]}[1]}}} eq $loc2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[1]}[0] == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$Data::Locations::{${${$stack}[1]}[1]}}} eq $loc1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str = $loc1->read();

if ($str eq '[3]')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$stack} == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[0]}[0] == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$Data::Locations::{${${$stack}[0]}[1]}}} eq $loc3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[1]}[0] == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$Data::Locations::{${${$stack}[1]}[1]}}} eq $loc2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[2]}[0] == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$Data::Locations::{${${$stack}[2]}[1]}}} eq $loc1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str = <$loc1>;

if ($str eq '<[2]')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$stack} == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[0]}[0] == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$Data::Locations::{${${$stack}[0]}[1]}}} eq $loc2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[1]}[0] == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$Data::Locations::{${${$stack}[1]}[1]}}} eq $loc1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str = $loc1->read();

if ($str eq '[1]')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$stack} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[0]}[0] == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$Data::Locations::{${${$stack}[0]}[1]}}} eq $loc1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str = <$loc1>;

if ($str eq '[3]')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$stack} == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[0]}[0] == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$Data::Locations::{${${$stack}[0]}[1]}}} eq $loc3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[1]}[0] == 4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$Data::Locations::{${${$stack}[1]}[1]}}} eq $loc1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str = $loc1->read();

if ($str eq '<[1]')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$stack} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[0]}[0] == 5)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$Data::Locations::{${${$stack}[0]}[1]}}} eq $loc1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc1->print("<MORE>");

$str = <$loc1>;

if ($str eq '<MORE>')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$stack} == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (${${$stack}[0]}[0] == 6)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$Data::Locations::{${${$stack}[0]}[1]}}} eq $loc1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str = $loc1->read();

if (! defined $str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$stack} == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc1->print("<EOF>");

$str = <$loc1>;

if (! defined $str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{$stack} == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

delete ${*{$loc1}}{'stack'};

if (! exists ${*{$loc1}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = $loc1->read();

if (exists ${*{$loc1}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@text = ( "[1]>", "[2]>", "[3]", "<[2]", "[1]", "[3]", "<[1]", "<MORE>", "<EOF>" );

if (scalar(@list) == scalar(@text))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$index = 0;
foreach $item (@list)
{
    if ($item eq $text[$index++])
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$str = <$loc1>;

if (! defined $str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{${*{$loc1}}{'stack'}} == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

delete ${*{$loc1}}{'stack'};

if (! exists ${*{$loc1}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc3->print("<_>");

@list = $loc1->read();

if (exists ${*{$loc1}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@text = ( "[1]>", "[2]>", "[3]", "<_>", "<[2]", "[1]", "[3]", "<_>", "<[1]", "<MORE>", "<EOF>" );

if (scalar(@list) == scalar(@text))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$index = 0;
foreach $item (@list)
{
    if ($item eq $text[$index++])
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$str = <$loc1>;

if (! defined $str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{${*{$loc1}}{'stack'}} == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (! exists ${*{$loc2}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@list = <$loc2>;

if (exists ${*{$loc2}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

@text = ( "[2]>", "[3]", "<_>", "<[2]" );

if (scalar(@list) == scalar(@text))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$index = 0;
foreach $item (@list)
{
    if ($item eq $text[$index++])
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

$str = <$loc2>;

if (! defined $str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (@{${*{$loc2}}{'stack'}} == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (! exists ${*{$loc3}}{'stack'})
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$err = '';
$SIG{__WARN__} = sub { $err = join('', @_); };
local($^W) = 1;

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
$err = '';
$dummy = '';
$dummy .= ${*{$loc}}[3];
if ($err =~ /Use of uninitialized value/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (${*{$loc}}[4] eq "<END>")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->reset();
if ($loc->read() eq "<BEGIN>")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$err = '';
$str = $loc->read();
$dummy .= $str;
if ($err eq '')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($str eq "")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($loc->read() eq "<MARKER>")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$err = '';
$str = $loc->read();
$dummy .= $str;
if ($err eq '')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($str eq "")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($loc->read() eq "<END>")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! defined $loc->read())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! defined $loc->read())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->reset();
if (<$loc> eq "<BEGIN>")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$err = '';
$str = <$loc>;
$dummy .= $str;
if ($err eq '')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($str eq "")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (<$loc> eq "<MARKER>")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$err = '';
$str = <$loc>;
$dummy .= $str;
if ($err eq '')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (defined $str)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($str eq "")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (<$loc> eq "<END>")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! defined <$loc>)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! defined <$loc>)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->reset();
if (join('|', $loc->read()) eq '<BEGIN>||<MARKER>||<END>')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->reset();
if (join('|', <$loc>) eq '<BEGIN>||<MARKER>||<END>')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

