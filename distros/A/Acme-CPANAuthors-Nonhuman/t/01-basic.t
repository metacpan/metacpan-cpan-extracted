use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

BEGIN { plan skip_all => 'Need a built version of Acme::CPANAuthors::Nonhuman for this test' if -d '.git' }

use Test::Deep;
use Acme::CPANAuthors 0.16;

my $authors = Acme::CPANAuthors->new('Nonhuman');

isa_ok($authors, 'Acme::CPANAuthors');
ok(()= $authors->id, 'we have ids');

cmp_deeply(
    [ $authors->id ],
    superbagof('ETHER'),
    'ETHER is in the list of ids returned',
);

cmp_deeply(
    [ Acme::CPANAuthors->look_for('ETHER') ],
    superbagof({
        id => 'ETHER',
        name => 'Karen Etheridge',
        category => 'Nonhuman'
    }),
    'ETHER is found in this author package',
);

done_testing;
