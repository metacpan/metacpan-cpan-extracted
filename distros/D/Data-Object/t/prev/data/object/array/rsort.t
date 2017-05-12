use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Array';
can_ok 'Data::Object::Array', 'rsort';

use Scalar::Util 'refaddr';

subtest 'test the rsort method' => sub {
    my $array = Data::Object::Array->new(['a'..'d']);

    my @argument = ();
    my $rsort = $array->rsort(@argument);

    isnt refaddr($array), refaddr($rsort);
    is_deeply $rsort, [qw(d c b a)];

    isa_ok $array, 'Data::Object::Array';
    isa_ok $rsort, 'Data::Object::Array';
};

ok 1 and done_testing;
