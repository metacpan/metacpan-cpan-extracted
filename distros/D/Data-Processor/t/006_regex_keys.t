use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $schema = {
    'foo.*' => {
        regex => 1,
        members => {
            one => {
                value => qr{what.*}
            },
            two => {
                value => qr{something.*}
            }
        }
    },
    bar => {
        members => {
            bar_one => {
                value => qr{not_there}
            }
        }
    },
};

my $data = {
    'fooo' => {
        one => 'whatever',
        two => 'something else'
    },
    'foo'  => 'error: members missing',
    'fo'   => 'not in schema',

    bar => 'empty'
};

my $p = Data::Processor->new($schema);

my $error_collection = $p->validate($data, verbose=>0);

ok ($error_collection->count==3, '3 errors detected');

ok ($error_collection->any_error_contains(
        string => 'should have members',
        field  => 'message'
    ),
    'config leaf that should be branch detected'
);




done_testing;
