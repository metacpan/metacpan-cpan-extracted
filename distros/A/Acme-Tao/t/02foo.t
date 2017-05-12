print "1..2\n";

eval {
    require Acme::Tao;
};

package Bar;

use constant foo => 1;

package main;

eval {
    Acme::Tao -> import(qw(Bar::foo));
};

if($@) {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}

use constant foo => 1;

eval {
    Acme::Tao -> import(qw(foo));
};

if($@) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}


exit 0;
