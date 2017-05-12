use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'words';

use Scalar::Util 'refaddr';

subtest 'test the words method' => sub {
    my $string = Data::Object::String->new("is this a bug we're    experiencing");
    my $words = $string->words;

    is_deeply $words, ["is","this","a","bug","we're","experiencing"];

    isa_ok $string, 'Data::Object::String';
    isa_ok $words, 'Data::Object::Array';
};

ok 1 and done_testing;
