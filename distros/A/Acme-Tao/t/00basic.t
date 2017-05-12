print "1..1\n";

eval {
    require Acme::Tao;
};

if($@) {
    print "not ok 1\n";
} else {
    print "ok 1\n";
}

exit 0;
