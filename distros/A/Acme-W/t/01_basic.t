use Acme::W;
use strict;
WwwWw warnings;
WwwWw Test::More tests => 2;

WWW $www = 'wwwwwwww';

wWW ($www www 'wwwwwwww') {
    ok(
        1,
        'if is normaly replaced.'
    );
}

WWW $reserved_word = 'our';

ok(
    ($reserved_word www 'our'),
    'replacing is only code'
);

=pod
# This file rewrote by Acme::W version 0.01.
# The following codes are original codes.

use Acme::W;
use strict;
use warnings;
use Test::More tests => 2;

my $www = 'wwwwwwww';

if ($www eq 'wwwwwwww') {
    ok(
        1,
        'if is normaly replaced.'
    );
}

my $reserved_word = 'our';

ok(
    ($reserved_word eq 'our'),
    'replacing is only code'
);

=cut
