# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('偁偆e' =~ /(偁[偄-偊]e)/) {
    if ("$1" eq "偁偆e") {
        print "ok - 1 $^X $__FILE__ ('偁偆e' =~ /偁[偄-偊]e/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('偁偆e' =~ /偁[偄-偊]e/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('偁偆e' =~ /偁[偄-偊]e/).\n";
}

__END__
