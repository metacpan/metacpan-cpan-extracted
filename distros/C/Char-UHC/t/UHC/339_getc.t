# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

use UHC;
print "1..1\n";

my $__FILE__ = __FILE__;

my @getc = ();
while (my $c = UHC::getc(DATA)) {
    last if $c =~ /\A[\r\n]\z/;
    push @getc, $c;
}
my $result = join('', map {"($_)"} @getc);

if ($result eq '(1)(2)(궇)(궋)') {
    print "ok - 1 $^X $__FILE__ 12궇궋 --> $result.\n";
}
else {
    print "not ok - 1 $^X $__FILE__ 12궇궋 --> $result.\n";
}

__END__
12궇궋
