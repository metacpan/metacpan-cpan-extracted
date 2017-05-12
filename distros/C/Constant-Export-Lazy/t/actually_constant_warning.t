package TestConstant;
use strict;
use warnings;
use Constant::Export::Lazy (
    constants => {
        TRUE   => sub { 1 },
        FALSE  => sub { 0 },
    }
);

package main;
BEGIN {
    TestConstant->import(qw(
        TRUE
        FALSE
    ));
}
my @warnings;
BEGIN {
    $SIG{__WARN__} = sub {
        chomp(my ($warn) = @_);
        push @warnings => $warn;
        return;
    };
}
sub TRUE {}
sub FALSE () {}
use Test::More tests => 3;

my @tests = (
    qr/Prototype mismatch: sub main::TRUE \(\) vs none/,
    qr/Constant subroutine TRUE redefined/,
    qr/Constant subroutine FALSE redefined/,
);

for my $test (@tests) {
    my @match;
    for my $warning (@warnings) {
        if ($warning =~ $test) {
            push @match => $warning;
        }
    }
    cmp_ok(scalar @match, '==', 1, "Each test should match one warning. The test <$test> matched <@match>");
}
