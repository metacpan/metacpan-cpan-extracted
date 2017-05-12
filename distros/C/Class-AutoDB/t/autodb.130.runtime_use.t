use t::lib;
use strict;
use autodbRunTests;

# Regression test: runtime use
# all classes use the same collection. 
# the 'put' test stores objects of different classes in the collection 
# the 'get' test gets objects from the collection w/o first using their classes
#   some cases should be okay; others should fail 

runtests_main();
