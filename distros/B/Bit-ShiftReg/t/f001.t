#!perl -w

use strict;
no strict "vars";

use Bit::ShiftReg qw(:all);

# ======================================================================
#   $bits = bits_of_byte();
#   $bits = bits_of_short();
#   $bits = bits_of_int();
#   $bits = bits_of_long();
# ======================================================================

print "1..4\n";

$n = 1;
if (bits_of_byte() >= 8)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (bits_of_short() >= 8)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (bits_of_int() >= 16)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (bits_of_long() >= 16)
{print "ok $n\n";} else {print "not ok $n\n";}

__END__

