# encoding: Big5
use Big5;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('-' =~ /([\D])/) {
    if ("-" eq "-") {
        print "ok - 1 $^X $__FILE__ ('-' =~ /[\\D]/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('-' =~ /[\\D]/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('-' =~ /[\\D]/).\n";
}

__END__
