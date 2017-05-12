# encoding: Latin2
# This file is encoded in Latin-2.
die "This file is not encoded in Latin-2.\n" if q{ } ne "\x82\xa0";

use Latin2;
print "1..1\n";

my $__FILE__ = __FILE__;

my @getc = ();
while (my $c = Latin2::getc(DATA)) {
    last if $c =~ /\A[\r\n]\z/;
    push @getc, $c;
}
my $result = join('', map {"($_)"} @getc);

if ($result eq '(1)(2)(ą)(˛)') {
    print "ok - 1 $^X $__FILE__ 12ą˛ --> $result.\n";
}
else {
    print "not ok - 1 $^X $__FILE__ 12ą˛ --> $result.\n";
}

__END__
12ą˛
