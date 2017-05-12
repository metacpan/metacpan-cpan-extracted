print "In the pre-DWIM light...\n";

use Acme::DWIM;

my ($x) = +("Hullo " x 3 . "world" & "~" x 30) =~ /(.*)/;
$x =~ tr/tnv/uow/;
print $x;
