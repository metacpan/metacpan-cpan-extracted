use Test::More;

my $Proto = 'Data::Object::Prototype';

use_ok $Proto;
can_ok $Proto, 'new', 'class', 'create', 'extend';

my $Bear = $Proto->create(
    '$name'     => [is => 'ro'],
    '$type'     => [is => 'ro'],
    '$attitude' => [is => 'ro'],
    '&responds' => sub { 'Roarrrr' },
);

my $bear = $Bear->new(
    name     => 'bear',
    type     => 'black bear',
    attitude => 'indifferent',
);

isa_ok $bear, 'Data::Object::Prototype::Instance';

my $papa = $Bear->prototype->extend->new(
    name     => 'papa bear',
    type     => 'great big papa bear',
    attitude => 'agitated',
);

$papa->package->method(responds => sub {
    "Who's been eating my porridge?"
});

my $baby = $Bear->prototype->extend->new(
    name     => 'baby bear',
    type     => 'tiny little baby bear',
    attitude => 'baby',
);

$baby->package->method(responds => sub {
    "Who's eaten up all my porridge?"
});

my $mama = $Bear->prototype->extend->new(
    name     => 'mama bear',
    type     => 'middle-sized mama bear',
    attitude => 'confused',
);

$mama->package->method(responds => sub {
    "Who's been eating my porridge?"
});

ok $papa && $mama && $baby, '$papa and $mama and $baby ok';

is $papa->name, 'papa bear', '$papa bear name is ok';
is $mama->name, 'mama bear', '$mama bear name is ok';
is $baby->name, 'baby bear', '$baby bear name is ok';

is $papa->responds, "Who's been eating my porridge?", '$papa responds ok';
is $mama->responds, "Who's been eating my porridge?", '$mama responds ok';
is $baby->responds, "Who's eaten up all my porridge?", '$baby responds ok';
is $bear->responds, 'Roarrrr', '$bear responds ok';

ok 1 and done_testing;
