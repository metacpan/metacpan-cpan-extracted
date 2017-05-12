#! perl -w
use warnings;
use strict;

use Test::More;
use Test::NoWarnings ();

use Dancer::RPCPlugin::FlattenData;

{
    my $bool = 1;
    my $complicated = [
        'scalar',
        ['array', 'of', 'strings'],
        {
            hash => bless(
                {
                    go   => 'wild',
                    list => bless([1, 2], 'OtherClass'),
                    scalar => bless(\$bool, 'Bool'),
                },
                'SomeClass'
            ),
        }
    ];

    my $flat = flatten_data($complicated);

    is_deeply(
        $flat,
        [
            'scalar',
            ['array', 'of', 'strings'],
            {
                hash => {go => 'wild', list => [1,2], scalar => 1},
            }
        ],
        "Flatten some data"
    ) or diag(explain($flat));
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
