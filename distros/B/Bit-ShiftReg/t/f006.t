#!perl -w

use strict;
no strict "vars";

use Bit::ShiftReg qw(:all);

# ======================================================================
#   $carry = ROL_long($value);
#   $carry = ROR_long($value);
#   $carry = SHL_long($value,$carry);
#   $carry = SHR_long($value,$carry);
# ======================================================================

print "1..38\n";

$n = 1;
$value = hex("1E");
if (ROL_long($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("3C"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (ROL_long($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("5A");
if (ROR_long($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("2D"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("55");
if (ROR_long($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_long($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_long($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (ROR_long($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("1E");
if (SHL_long($value,0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("3C"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("1E");
if (SHL_long($value,1) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("3D"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (SHL_long($value,0) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_long($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_long($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (SHL_long($value,1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_long($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_long($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("5A");
if (SHR_long($value,0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("2D"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("55");
if (SHR_long($value,1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_long($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_long($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (SHR_long($value,0) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_long($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_long($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (SHR_long($value,1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_long($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_long($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

