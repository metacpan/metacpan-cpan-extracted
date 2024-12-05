use Test2::V0 -no_srand => 1;
use Data::Section::Pluggable;
use lib 'corpus/lib';

eval { require DataOnly };

# this is honestly the dumbest of corner cases but here we go.
is(
    Data::Section::Pluggable->new,
    object {
        call get_data_section => {
            'a.txt' => "Hello World!\n",
        };
    },
    'handle file with just __DATA__ section',
);

done_testing;
