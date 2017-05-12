package TestImportingWithUniversal;
use strict;
use warnings;
use Test::More tests => 2;
use UNIVERSAL; # Creates UNIVERSAL::import()
BEGIN {
    my @warnings;
    eval {
        local $SIG{__WARN__} = sub {
            chomp(my ($warn) = @_);
            push @warnings => $warn;
            return;
        };
        require Constant::Export::Lazy;
        Constant::Export::Lazy->import(
            constants => {
                UNUSED => sub { 1 },
            },
        );
        pass "We managed to import() under UNIVERSAL!";
        1;
    } or do {
        my $error = $@ || "Zombie Error";
        fail "We failed to import: <$error>";
    };
    cmp_ok(scalar @warnings, '==', 0, "We should get no warnings when importing with UNIVERSAL in effect");
}
