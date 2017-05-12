use warnings;
use strict;
use Test::More;

use Data::DPath::Validator;

my $vloose = Data::DPath::Validator->new();
my $vstrict = Data::DPath::Validator->new(strict_mode => 1);

my $template =
{
    foo =>
    {
        faa =>
        [
            1,
            2,
            3,
            '*',
            {
                gar =>
                {
                    zar => '*'
                }
            },
        ],
    },
    bar =>
    {
        baa =>
        [
            {
                qwe => '*',
                fla => [ qw/1 2 3 4/],
            }
        ],
    },
    baz =>
    {
        zaa =>
        [
            '*',
            'yarg'
        ],
    },
};

$vloose->load('zarp', 'fluawe', $template);
$vstrict->load($template);

is($vloose->validate({foo => { faa => [undef, undef, undef, { random_stuff => ['floo'] }]}})->[0], 1, 'loose validation of nested asterisk 1');
is($vloose->validate({foo => { faa => [undef, undef, undef, { random_stuff => ['floo'] }, { gar => {zar => { srga => '2' } } }]}})->[0], 1, 'loose validation of nested asterisk 2');
is_deeply($vloose->validate({baz => 1}, {baz => { zaa => [ 1 ] } }, {baz => { zaa => [ [ 1 ], 'yarg' ]}}, 'zarp' ), [1,1,1,1], 'multiple loose validation');

my $strict_data =
{
    foo =>
    {
        faa =>
        [
            1,
            2,
            3,
            { sdfsdfsdf => [ { afaf => [ { werwer => [ 3 ] } ] } ] },
            {
                gar =>
                {
                    zar => 1
                }
            },
        ],
    },
    bar =>
    {
        baa =>
        [
            {
                qwe => [ { cvbcvb => 2 }, { sdfsdf => 3 } ],
                fla => [ qw/1 2 3 4/],
            }
        ],
    },
    baz =>
    {
        zaa =>
        [
            { bcxvb => { fgghj => { qaewrs => { qwezxnju => 1 } } } },
            'yarg'
        ],
    },
};

is($vstrict->validate($strict_data)->[0], 1, 'strict validation');

done_testing();
