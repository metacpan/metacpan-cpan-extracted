# encoding: Hebrew
use Hebrew;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('1' =~ /(\d)/) {
    if ("-" eq "-") {
        print "ok - 1 $^X $__FILE__ ('1' =~ /\\d/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('1' =~ /\\d/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('1' =~ /\\d/).\n";
}

__END__
