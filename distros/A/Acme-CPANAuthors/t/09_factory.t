use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;
use Acme::CPANAuthors::Factory;

my $authors = Acme::CPANAuthors::Factory->create(
    Nonhuman => {
        ETHER => 'Karen Etheridge',
    },
    Japanese => {
        ISHIGAKI => 'Kenichi Ishigaki',
    },
);

is($authors->count, 2, 'author count');

is($authors->id, 2, 'author ids');

ok($authors->id('ISHIGAKI'), 'ISHIGAKI is a member');

my @names = $authors->name;
is(@names, 2, 'author names');

like($authors->name('ISHIGAKI'), qr/Ishigaki/i, 'Ishigaki is a member');

my @categories = $authors->categories;
is(@categories, 2, '2 categories');
cmp_deeply(
    \@categories,
    bag(qw(Nonhuman Japanese)),
    'categories',
);

done_testing;
