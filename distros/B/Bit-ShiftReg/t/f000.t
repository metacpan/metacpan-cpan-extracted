#!perl -w

use strict;
no strict "vars";

use Bit::ShiftReg;

# ======================================================================
#   $version = Bit::ShiftReg::Version();
#   $version = $Bit::ShiftReg::VERSION;
# ======================================================================

print "1..2\n";

$n = 1;
if (Bit::ShiftReg::Version() eq "2.0")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($Bit::ShiftReg::VERSION eq "2.0")
{print "ok $n\n";} else {print "not ok $n\n";}

__END__

