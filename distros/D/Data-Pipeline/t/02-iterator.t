use Test::More tests => 19;

use Data::Pipeline::Iterator;
use Data::Pipeline::Iterator::Source;

my @things = (1..10);
my $source = Data::Pipeline::Iterator::Source -> new(
    has_next => sub { scalar(@things) > 0 },
    get_next => sub { shift @things }
);

my $it1 = Data::Pipeline::Iterator -> new(
     source => $source
);

my $it2 = Data::Pipeline::Iterator -> new(
     source => $source
);

is($it1 -> next, 1);
is($it1 -> next, 2);
is($it1 -> next, 3);
is($it1 -> next, 4);

is( scalar( @things ), 6 );

is($it2 -> next, 1);
is($it2 -> next, 2);
is($it2 -> next, 3);
is($it2 -> next, 4);

is( scalar( @things ), 6 );


is($it1 -> next, 5);
is($it1 -> next, 6);
is($it1 -> next, 7);
is($it1 -> next, 8);
is($it1 -> next, 9);
is($it1 -> next, 10);

is( scalar( @things ), 0 );

ok( $it1 -> finished );

ok( !$it2 -> finished );
