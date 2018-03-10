use strict;
use warnings;

use Cuckoo::Filter;
use Test::More;

my $filter = Cuckoo::Filter->new();
ok $filter->insert(1);
ok !$filter->insert(1);
ok $filter->insert(3);
ok $filter->insert(5);
ok $filter->lookup(5);
ok !$filter->lookup(4);
ok $filter->delete(5);
ok !$filter->lookup(5);

ok my $serialized = $filter->serialize();
my $filter2 = Cuckoo::Filter::deserialize($serialized);

ok $filter2->lookup(3);
ok !$filter2->lookup(5);

done_testing;
