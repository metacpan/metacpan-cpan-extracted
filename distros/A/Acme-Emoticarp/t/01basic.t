use strict;
use warnings;

use Test::More tests => 2;
use Acme::Emoticarp;

my $warning;

do {
    local $SIG{__WARN__} = sub {
        ( $warning ) = @_;
    };

    ಠ_ಠ 'I disapprove.';
};

like $warning, qr/I disapprove[.]/;

eval {
    o_O 'Uh oh!';
};
like $@, qr/Uh oh!/;
