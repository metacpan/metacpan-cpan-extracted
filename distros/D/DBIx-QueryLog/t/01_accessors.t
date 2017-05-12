use strict;
use warnings;
use Test::More;
use DBIx::QueryLog;

my $q = 'DBIx::QueryLog';

my $accessors = [qw(
    logger threshold probability skip_bind
    color useqq compact
)];

for my $accessor (@$accessors) {
    subtest $accessor => sub {
        is $q->$accessor, undef, 'default';
        ok $q->$accessor('foo'), 'set ok';
        is $q->$accessor, 'foo', 'get ok';
    };
}

done_testing;
