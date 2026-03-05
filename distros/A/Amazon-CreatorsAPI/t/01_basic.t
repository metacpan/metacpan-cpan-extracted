use strict;
use warnings;
use Test::More;

use Amazon::CreatorsAPI;

can_ok 'Amazon::CreatorsAPI', qw/new/;

{
    my $api = Amazon::CreatorsAPI->new(
        'test_id',
        'test_secret',
        '3.3',
    );
    isa_ok $api, 'Amazon::CreatorsAPI';
}

done_testing;
