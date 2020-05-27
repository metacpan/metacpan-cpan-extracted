use Data::AnyXfer::Test::Kit;

use MooseX::ClassCompositor;

my $role = 'Data::AnyXfer::Elastic::Role::BucketSimplifier';

use_ok($role);

ok my $class
    = MooseX::ClassCompositor->new( { class_basename => "Test::${role}", } )
    ->class_for($role),
    'test class';

has_attribute_ok $class, qw/ aggregations_key /;

can_ok $class, qw/ simplify_bucket /;

ok my $obj = $class->new( aggregations_key => 'aggs_test' ), 'new instance';

ok my $key = $obj->aggregations_key, 'aggregations_key';

my $data = {
    $key => {
        data => {
            buckets => [
                {   key           => 64,
                    key_as_string => 'AAA',
                    doc_count     => { value => 4 },
                    foobars       => {
                        buckets => [
                            {   key       => 'LON',
                                doc_count => 1,
                            },
                            {   key       => 'SHO',
                                doc_count => 3,
                                avg_price => { value => 100 },
                                tot_price => { value => 300 },
                            },
                        ],
                    },
                },
                {   key           => 65,
                    key_as_string => 'BBB',
                    doc_count     => { value => 7 },
                    foobars       => {
                        buckets => [
                            {   key       => 'LON',
                                doc_count => 4,
                            },
                            {   key       => 'SHO',
                                doc_count => 2,
                            },
                            {   key       => 'EVT',
                                doc_count => 1,
                            },
                        ],
                    },
                }

            ],
        }
    }
};

my $res;

lives_ok {
    ok $res = $obj->simplify_bucket($data), 'simplify_bucket';
}
'no error';

is_deeply $res,
    {
    'data' => {
        'AAA' => {
            'doc_count' => 4,
            'foobars'   => {
                'LON' => { 'doc_count' => 1 },
                'SHO' => {
                    'avg_price' => 100,
                    'doc_count' => 3,
                    'tot_price' => 300
                }
            }
        },
        'BBB' => {
            'doc_count' => 7,
            'foobars'   => {
                'EVT' => { 'doc_count' => 1 },
                'LON' => { 'doc_count' => 4 },
                'SHO' => { 'doc_count' => 2 }
            }
        }
    }
    },
    'expected result';

note( explain $res);

done_testing;
