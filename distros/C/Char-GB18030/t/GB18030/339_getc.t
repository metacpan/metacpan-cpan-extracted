# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..1\n";

my $__FILE__ = __FILE__;

my @getc = ();
while (my $c = GB18030::getc(DATA)) {
    last if $c =~ /\A[\r\n]\z/;
    push @getc, $c;
}
my $result = join('', map {"($_)"} @getc);

if ($result eq '(1)(2)(偁)(偄)(辈)(炒)(񵼐)(񼭮)') {
    print "ok - 1 $^X $__FILE__ 12偁偄辈炒񵼐񼭮 --> $result.\n";
}
else {
    print "not ok - 1 $^X $__FILE__ 12偁偄辈炒񵼐񼭮 --> $result.\n";
}

__END__
12偁偄辈炒񵼐񼭮
