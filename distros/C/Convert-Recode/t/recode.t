print "1..3\n";

use Convert::Recode qw(iso646no_to_latin1 latin1_to_iso646no);

print "not " unless iso646no_to_latin1("v}re norske tegn b|r {res") eq
                                       "våre norske tegn bør æres";
print "ok 1\n";

print "not " unless latin1_to_iso646no("ÆØÅæøå") eq "[\\]{|}";
print "ok 2\n";

use Convert::Recode qw(strict_latin1_to_iso646no);

print "not " unless strict_latin1_to_iso646no("{}æøå¹²³") eq "{|}";
print "ok 3\n";


