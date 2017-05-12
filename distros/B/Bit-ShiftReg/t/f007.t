#!perl -w

use strict;
no strict "vars";

use Bit::ShiftReg qw(:all);

# ======================================================================
#   $carry = ROL_32($value);
#   $carry = ROR_32($value);
#   $carry = SHL_32($value,$carry);
#   $carry = SHR_32($value,$carry);
# ======================================================================

if (bits_of_byte() != 8)
{
    print "1..1\n";
    print "not ok 1\n";
    exit;
}
else
{
    print "1..60\n";
}

$n = 1;
$byte3 = hex("FF");
$byte2 = hex("FF");
$byte1 = hex("FF");
$byte0 = hex("FF");
if (SHL_byte($byte3, SHL_byte($byte2, SHL_byte($byte1, # ROL
    SHL_byte($byte0, MSB_byte($byte3))))) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte0 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte1 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte2 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte3 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$byte3 = hex("FF");
$byte2 = hex("FF");
$byte1 = hex("FF");
$byte0 = hex("FF");
if (SHR_byte($byte0, SHR_byte($byte1, SHR_byte($byte2, # ROR
    SHR_byte($byte3, LSB_byte($byte0))))) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte0 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte1 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte2 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte3 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$byte3 = hex("FF");
$byte2 = hex("FF");
$byte1 = hex("FF");
$byte0 = hex("FF");
if (SHL_byte($byte3, SHL_byte($byte2, SHL_byte($byte1, # SHL
    SHL_byte($byte0, 1)))) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte0 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte1 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte2 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte3 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$byte3 = hex("FF");
$byte2 = hex("FF");
$byte1 = hex("FF");
$byte0 = hex("FF");
if (SHR_byte($byte0, SHR_byte($byte1, SHR_byte($byte2, # SHR
    SHR_byte($byte3, 1)))) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte0 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte1 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte2 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte3 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$byte3 = hex("FF");
$byte2 = hex("FF");
$byte1 = hex("FF");
$byte0 = hex("FF");
if (SHL_byte($byte3, SHL_byte($byte2, SHL_byte($byte1, # SHL
    SHL_byte($byte0, 0)))) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte0 == hex("FE"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte1 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte2 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte3 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$byte3 = hex("FF");
$byte2 = hex("FF");
$byte1 = hex("FF");
$byte0 = hex("FF");
if (SHR_byte($byte0, SHR_byte($byte1, SHR_byte($byte2, # SHR
    SHR_byte($byte3, 0)))) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte0 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte1 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte2 == hex("FF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte3 == hex("7F"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$byte3 = hex("81");
$byte2 = hex("7E");
$byte1 = hex("FF");
$byte0 = hex("5A");
if (SHL_byte($byte3, SHL_byte($byte2, SHL_byte($byte1, # ROL
    SHL_byte($byte0, MSB_byte($byte3))))) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte0 == hex("B5"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte1 == hex("FE"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte2 == hex("FD"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte3 == hex("02"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$byte3 = hex("81");
$byte2 = hex("7E");
$byte1 = hex("FF");
$byte0 = hex("5A");
if (SHR_byte($byte0, SHR_byte($byte1, SHR_byte($byte2, # ROR
    SHR_byte($byte3, LSB_byte($byte0))))) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte0 == hex("AD"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte1 == hex("7F"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte2 == hex("BF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte3 == hex("40"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$byte3 = hex("81");
$byte2 = hex("7E");
$byte1 = hex("FF");
$byte0 = hex("5A");
if (SHL_byte($byte3, SHL_byte($byte2, SHL_byte($byte1, # SHL
    SHL_byte($byte0, 0)))) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte0 == hex("B4"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte1 == hex("FE"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte2 == hex("FD"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte3 == hex("02"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$byte3 = hex("81");
$byte2 = hex("7E");
$byte1 = hex("FF");
$byte0 = hex("5A");
if (SHL_byte($byte3, SHL_byte($byte2, SHL_byte($byte1, # SHL
    SHL_byte($byte0, 1)))) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte0 == hex("B5"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte1 == hex("FE"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte2 == hex("FD"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte3 == hex("02"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$byte3 = hex("81");
$byte2 = hex("7E");
$byte1 = hex("FF");
$byte0 = hex("5A");
if (SHR_byte($byte0, SHR_byte($byte1, SHR_byte($byte2, # SHR
    SHR_byte($byte3, 0)))) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte0 == hex("AD"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte1 == hex("7F"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte2 == hex("BF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte3 == hex("40"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$byte3 = hex("81");
$byte2 = hex("7E");
$byte1 = hex("FF");
$byte0 = hex("5A");
if (SHR_byte($byte0, SHR_byte($byte1, SHR_byte($byte2, # SHR
    SHR_byte($byte3, 1)))) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte0 == hex("AD"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte1 == hex("7F"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte2 == hex("BF"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($byte3 == hex("C0"))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

