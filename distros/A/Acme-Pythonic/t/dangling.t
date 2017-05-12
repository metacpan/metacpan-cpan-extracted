use Test::More 'no_plan';
use Acme::Pythonic debug => 0;

# This checks whether the stack gets emptied. If it is not it does not
# compile.

# It's important that this file ends in the ok 1 line.

no warnings
if 1:
   unless 0:
       $n = 0
       $m = 1
       ok 1