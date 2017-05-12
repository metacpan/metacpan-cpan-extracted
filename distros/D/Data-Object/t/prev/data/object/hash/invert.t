use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Hash';
can_ok 'Data::Object::Hash', 'invert';

use Scalar::Util 'refaddr';

subtest 'test the invert method' => sub {
    my $hash = Data::Object::Hash->new({1..8,9,undef,10,''});

    my @argument = ();
    my $invert = $hash->invert(@argument);

    isnt refaddr($hash), refaddr($invert);
    is_deeply $invert, {''=>10,2=>1,4=>3,6=>5,8=>7};

    isa_ok $hash, 'Data::Object::Hash';
    isa_ok $invert, 'Data::Object::Hash';
};

ok 1 and done_testing;
