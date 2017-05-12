#!perl -w

use strict;
no strict "vars";

use Bit::ShiftReg qw(:all);

# ======================================================================
#   $carry = ROL_byte($value);
#   $carry = ROR_byte($value);
#   $carry = SHL_byte($value,$carry);
#   $carry = SHR_byte($value,$carry);
# ======================================================================

print "1..38\n";

$n = 1;
$value = hex("1E");
if (ROL_byte($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("3C"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (ROL_byte($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("5A");
if (ROR_byte($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("2D"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("55");
if (ROR_byte($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_byte($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_byte($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (ROR_byte($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("1E");
if (SHL_byte($value,0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("3C"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("1E");
if (SHL_byte($value,1) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("3D"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (SHL_byte($value,0) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_byte($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_byte($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (SHL_byte($value,1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_byte($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_byte($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("5A");
if (SHR_byte($value,0) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value == hex("2D"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = hex("55");
if (SHR_byte($value,1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_byte($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_byte($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (SHR_byte($value,0) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_byte($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_byte($value) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$value = -1;
if (SHR_byte($value,1) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($value != 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (LSB_byte($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (MSB_byte($value) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

