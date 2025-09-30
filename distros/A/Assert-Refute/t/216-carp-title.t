#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More tests => 3;

use Assert::Refute qw(assert_refute);

my @warn;
my $alive = eval {
    local $SIG{__WARN__} = sub { push @warn, shift };
    assert_refute {
        package T;
        use Assert::Refute qw(:all);
        plan tests => 1, title => 'Foobared';
        is 42, 137, 'life is fine';
    };
    1;
};

is $alive, 1, "code lives"
    or diag "Died: $@";

is scalar @warn, 1, "1 warning";
note "<REPORT>";
note $warn[0] || '(none)';
note "</REPORT>";
like $warn[0], qr/not ok 1.*Contract.*\bFoobared\b.*/s, "warning as expected";

