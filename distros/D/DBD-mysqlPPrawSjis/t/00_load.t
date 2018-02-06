use FindBin;
use lib "$FindBin::Bin/../lib";

print "1..2\n";

require DBI;
print "ok 1\n";
require DBD::mysqlPPrawSjis;
print "ok 2\n";
