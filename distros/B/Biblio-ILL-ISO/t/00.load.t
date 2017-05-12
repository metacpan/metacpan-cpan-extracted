
BEGIN { $| = 1; print "1..1\n"; }
END   { print "not ok 1\n" unless $loaded; }

use Biblio::ILL::ISO::ISO;

$loaded = 1;
print "ok\n";

