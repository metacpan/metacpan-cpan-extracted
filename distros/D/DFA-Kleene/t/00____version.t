#!perl -w

use strict;
no strict "vars";

use DFA::Kleene;

# ======================================================================
#   $DFA::Kleene::VERSION
# ======================================================================

print "1..1\n";

$n = 1;
if ($DFA::Kleene::VERSION eq "1.0")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

