use Test;

use strict;

sub t {
    open FH, ">foo.in" or die "$!: foo.in";
    print FH @_        or die "$!: foo.in";
    close FH           or die "$!: foo.in";
    system( "$^X foo.in >foo.out 2>foo.err" );;

    local $/ = undef;
 
    open FH, "foo.out" or die "$!: foo.out";
    my $out = <FH>;
    open FH, "foo.err" or die "$!: foo.err";
    my $err = <FH>;
    close FH           or die "$!: foo.err";
    
    return "<$out><$err>";
}

my @tests = (
sub {
    my $out = t<<'CODE_END';
my $bar = "BAR";
warn "hello"; use BFD; d $bar;
warn "there";
CODE_END

    $out =~ /\A<><.*hello.*BAR.*there/s
        ? ok $out, $out
        : ok $out, "hello.*BAR.*there";
},
);

plan tests => 0+@tests;

$_->() for @tests;
