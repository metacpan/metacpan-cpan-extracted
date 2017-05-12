package TestImportingBase;
use strict;
use warnings;

sub import { die "I won't be called or discovered" }

package TestImportingWithBase;
use strict;
use warnings;
use base qw(TestImportingBase);
use Test::More tests => 2;
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
        pass "We managed to import() into a class that has a base class with an import()!";
        1;
    } or do {
        my $error = $@ || "Zombie Error";
        fail "We failed to import: <$error>";
    };
    cmp_ok(scalar @warnings, '==', 0, "We should get no warnings when importing into a class that has a base class with an import()");
}
