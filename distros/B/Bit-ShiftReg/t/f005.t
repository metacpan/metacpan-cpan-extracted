#!perl -w

use strict;
no strict "vars";

use Bit::ShiftReg qw(:all);

# ======================================================================
#   $carry = ROL_int($value);
#   $carry = ROR_int($value);
#   $carry = SHL_int($value,$carry);
#   $carry = SHR_int($value,$carry);
# ======================================================================

print "1..38\n";

$n = 1;
$value = hex("1E");
if (ROL_int($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("3C"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (ROL_int($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("5A");
if (ROR_int($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("2D"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("55");
if (ROR_int($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_int($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_int($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (ROR_int($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("1E");
if (SHL_int($value,0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("3C"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("1E");
if (SHL_int($value,1) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("3D"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (SHL_int($value,0) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_int($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_int($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (SHL_int($value,1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_int($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_int($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("5A");
if (SHR_int($value,0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("2D"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("55");
if (SHR_int($value,1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_int($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_int($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (SHR_int($value,0) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_int($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_int($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (SHR_int($value,1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_int($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_int($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

