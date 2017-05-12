use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

BEGIN { plan skip_all => 'Need a built version of Acme::CPANAuthors::Nonhuman for this test' if -d '.git' }

use Test::Deep;
use Acme::CPANAuthors::Nonhuman;

my $authors = 'Acme::CPANAuthors::Nonhuman';

cmp_deeply(
    { $authors->authors },
    superhashof({ ETHER => 'Karen Etheridge' }),
    'ETHER is in the list of ids returned (list context)',
);

cmp_deeply(
    scalar $authors->authors,
    superhashof({ ETHER => 'Karen Etheridge' }),
    'ETHER is in the hashref of ids returned (scalar context)',
);

is($authors->category, 'Nonhuman', 'respect the "category" interface');

# old: http://www.gravatar.com/avatar/bdc5cd06679e732e262f6c1b450a0237?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2Fbdc5cd06679e732e262f6c1b450a0237
# new: https://secure.gravatar.com/avatar/bdc5cd06679e732e262f6c1b450a0237?s=80&d=identicon
like($authors->avatar_url('ETHER'), qr{^https://}, 'we (via metacpan) return secure gravatars, rather than the junky old ones');

done_testing;
