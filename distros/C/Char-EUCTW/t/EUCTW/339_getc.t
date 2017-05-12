# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{あ} ne "\xa4\xa2";

use EUCTW;
print "1..1\n";

my $__FILE__ = __FILE__;

my @getc = ();
while (my $c = EUCTW::getc(DATA)) {
    last if $c =~ /\A[\r\n]\z/;
    push @getc, $c;
}
my $result = join('', map {"($_)"} @getc);

if ($result eq '(1)(2)(あ)(い)(｡あ)(｢あ)(｣あ)(､あ)(･あ)(ｦあ)(ｧあ)(ｨあ)(ｩあ)(ｪあ)(ｫあ)(ｬあ)(ｭあ)(ｮあ)(ｯあ)(ｰあ)') {
    print "ok - 1 $^X $__FILE__ 12あい｡あ｢あ｣あ､あ･あｦあｧあｨあｩあｪあｫあｬあｭあｮあｯあｰあ --> $result.\n";
}
else {
    print "not ok - 1 $^X $__FILE__ 12あい｡あ｢あ｣あ､あ･あｦあｧあｨあｩあｪあｫあｬあｭあｮあｯあｰあ --> $result.\n";
}

__END__
12あい｡あ｢あ｣あ､あ･あｦあｧあｨあｩあｪあｫあｬあｭあｮあｯあｰあ
