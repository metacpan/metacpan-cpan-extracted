# encoding: Hebrew
# This file is encoded in Hebrew.
die "This file is not encoded in Hebrew.\n" if q{ } ne "\x82\xa0";

use Hebrew;
print "1..1\n";

my $__FILE__ = __FILE__;

my @getc = ();
while (my $c = Hebrew::getc(DATA)) {
    last if $c =~ /\A[\r\n]\z/;
    push @getc, $c;
}
my $result = join('', map {"($_)"} @getc);

if ($result eq '(1)(2)(±)(²)') {
    print "ok - 1 $^X $__FILE__ 12±² --> $result.\n";
}
else {
    print "not ok - 1 $^X $__FILE__ 12±² --> $result.\n";
}

__END__
12±²
