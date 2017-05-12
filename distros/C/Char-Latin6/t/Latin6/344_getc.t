# encoding: Latin6
# This file is encoded in Latin-6.
die "This file is not encoded in Latin-6.\n" if q{‚ } ne "\x82\xa0";

use Latin6 qw(getc);
print "1..2\n";

my $__FILE__ = __FILE__;

open(FILE,">$__FILE__.txt") || die;
print FILE <DATA>;
close(FILE);

open(GETC,"<$__FILE__.txt") || die;
my @getc = ();
while (my $c = getc(GETC)) {
    last if $c =~ /\A[\r\n]\z/;
    push @getc, $c;
}
close(GETC);

my $result = join('', map {"($_)"} @getc);
if ($result eq '(1)(2)(±)(²)') {
    print "ok - 1 $^X $__FILE__ 12±² --> $result.\n";
}
else {
    print "not ok - 1 $^X $__FILE__ 12±² --> $result.\n";
}

{
    package Getc::Test;

    open(GETC2,"<$__FILE__.txt") || die;
    my @getc = ();
    while (my $c = getc(GETC2)) {
        last if $c =~ /\A[\r\n]\z/;
        push @getc, $c;
    }
    close(GETC2);

    my $result = join('', map {"($_)"} @getc);
    if ($result eq '(1)(2)(±)(²)') {
        print "ok - 1 $^X $__FILE__ 12±² --> $result.\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ 12±² --> $result.\n";
    }
}

unlink("$__FILE__.txt");

__END__
12±²
