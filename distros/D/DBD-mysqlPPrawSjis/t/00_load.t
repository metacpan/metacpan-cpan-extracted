use FindBin;
use lib "$FindBin::Bin/../lib";

print "1..1\n";
eval {
    require DBI;
};
if ($@) {
    print "ok 1 - SKIP DBI module not found\n";
}
else {
    eval {
        require DBD::mysqlPPrawSjis;
    };
    if ($@) {
        print "not ok 1($@)\n";
    }
    else {
        print "ok 1\n";
    }
}
