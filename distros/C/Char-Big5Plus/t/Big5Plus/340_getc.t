# encoding: Big5Plus
# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{‚ } ne "\x82\xa0";

use Big5Plus;
print "1..1\n";

my $__FILE__ = __FILE__;

my @getc = ();
while (my $c = Big5Plus::getc(DATA)) {
    last if $c =~ /\A[\r\n]\z/;
    push @getc, $c;
}
my $result = join('', map {"($_)"} @getc);

if ($result eq '(1)(2)(‚ )(‚¢)') {
    print "ok - 1 $^X $__FILE__ 12‚ ‚¢ --> $result.\n";
}
else {
    print "not ok - 1 $^X $__FILE__ 12‚ ‚¢ --> $result.\n";
}

__END__
12‚ ‚¢
