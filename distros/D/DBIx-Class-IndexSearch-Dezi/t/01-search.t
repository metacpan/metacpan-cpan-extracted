use Test::More;

use lib 't/lib';

use strict;
use warnings;

BEGIN {
    use_ok('Test');
}

my $schema = Test->initialize;

my $resultset = $schema->resultset('Person');

my $person0 = $resultset->new({
    name    => 'FooBar',
    age     => 18,
});

$person0->insert;

my $results0 = $resultset->search_dezi( { name => 'Foo*' } );
is $results0->count, 1;

my $result0 = $results0->next;
ok $result0;

is $result0->name, 'FooBar';
is $result0->age, 18;

my $person1 = $resultset->new({
    name    => 'FooBarSimilar',
    age     => 20,
});
$person1->insert;

my $results1 = $resultset->search_dezi( { name => 'Foo*' } );
is $results1->count, 2;

my $result1 = $results1->next;
ok $result1;

is $result1->name, 'FooBar';
is $result1->age, 18;

my $result2 = $results1->next;
ok $result2;

is $result2->name, 'FooBarSimilar';
is $result2->age, 20;

done_testing;


