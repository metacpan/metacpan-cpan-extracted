use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'defined';

use Scalar::Util 'refaddr';

subtest 'test the defined method' => sub {
    my $hash = Data::Object::Hash->new({1..8,9,undef});

    my @argument = (1);
    my $defined = $hash->defined(@argument);

    isnt refaddr($hash), refaddr($defined);
    is $defined, 1;

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $defined, 'Data::Object::Number';
};

ok 1 and done_testing;
