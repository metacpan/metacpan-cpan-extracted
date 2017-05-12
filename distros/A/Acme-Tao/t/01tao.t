print "1..1\n";

eval {
    require Acme::Tao;
};

use constant Tao;

my $count = 0;
while($count < 1000) {
    eval {
        Acme::Tao -> import;
    };

    if($@) {
        print "ok 1\n";
        exit;
    }
    $count ++;
}

print "not ok 1\n" if $count > 999;

exit 0;
