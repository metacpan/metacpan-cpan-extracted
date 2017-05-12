use strict;
use warnings;
use utf8;

{
    # to check behavior of two args
    package MyConfig::Two;
    use Config::ENV::Multi [qw/B C/];

    common                     +{ COMMON   => 1, match_ab => 0, match_c  => 0, };
    config [qw/    b1  * /] => +{ A1_B1_CW => 1, match_ab => 1, match_c  => 0, };
    config [qw/    b1 c1 /] => +{ A1_B1_C1 => 1, match_ab => 1, match_c  => 1, };
    1;
}

{
    package MyConfig::Three;
    use Config::ENV::Multi [qw/A B C/];

    common                     +{ COMMON   => 1, match_ab => 0, match_c  => 0, };
    config [qw/ a1 b1  * /] => +{ A1_B1_CW => 1, match_ab => 1, match_c  => 0, };
    config [qw/ a1 b1 c1 /] => +{ A1_B1_C1 => 1, match_ab => 1, match_c  => 1, };
    1;
}

use Test::More;
use Test::Deep;

test('MyConfig::Two');
test('MyConfig::Three');

sub test {
    my $class = shift;
    subtest $class => sub {

        subtest "when all members match specific config" => sub {

            local %ENV = (
                A => 'a1',
                B => 'b1',
                C => 'c1',
            );

            my $config = $class->current;

            cmp_deeply $config, superhashof(+{
                COMMON   => 1,
                A1_B1_CW => 1,
                A1_B1_C1 => 1,
            }),
            "should match all of configs and be set members by each of them" or note explain $config;

            cmp_deeply $config, superhashof(+{
                match_ab => 1,
                match_c  => 1,
            }),
            "most specific config should overwrite others" or note explain $config;

        };

        subtest "when one of members does not match specific config" => sub {

            local %ENV = (
                A => 'a1',
                B => 'b1',
                C => 'c2',
            );

            my $config = $class->current;

            cmp_deeply $config, superhashof(+{
                COMMON   => 1,
                A1_B1_CW => 1,
            }),
            "should match two of configs and be set members by each of them" or note explain $config;

            cmp_deeply $config, superhashof(+{
                match_ab => 1,
                match_c  => 0,
            }),
            "more specific config should overwrite others" or note explain $config;

        };
    }
}

done_testing;
