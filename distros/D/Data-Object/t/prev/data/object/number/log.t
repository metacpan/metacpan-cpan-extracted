use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';
can_ok 'Data::Object::Number', 'log';

use Scalar::Util 'refaddr';

subtest 'test the log method' => sub {
    my $number = Data::Object::Number->new(12345);
    my $log = $number->log();

    isnt refaddr($number), refaddr($log);
    like $log, qr/9.42100/;

    isa_ok $number, 'Data::Object::Number';
    isa_ok $log, 'Data::Object::Float';
};

ok 1 and done_testing;
