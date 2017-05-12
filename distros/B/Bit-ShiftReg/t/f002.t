#!perl -w

use strict;
no strict "vars";

use Bit::ShiftReg qw(:all);

# ======================================================================
#   $lsb = LSB_byte($value);
#   $msb = MSB_byte($value);
#   $lsb = LSB_short($value);
#   $msb = MSB_short($value);
#   $lsb = LSB_int($value);
#   $msb = MSB_int($value);
#   $lsb = LSB_long($value);
#   $msb = MSB_long($value);
# ======================================================================

print "1..16\n";

$n = 1;
if (LSB_byte(0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_byte(-1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_byte(0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_byte(-1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (LSB_short(0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_short(-1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_short(0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_short(-1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (LSB_int(0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_int(-1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_int(0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_int(-1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (LSB_long(0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_long(-1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_long(0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_long(-1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

