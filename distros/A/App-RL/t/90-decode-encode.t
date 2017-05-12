use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('App::RL::Common');
}

{
    print "#fas headers\n";

    my @data_fas_header = (
        [   q{S288c.I(+):27070-29557|species=yeast},
            {   name    => "S288c",
                chr     => "I",
                strand  => "+",
                start   => 27070,
                end     => 29557,
                species => "yeast",
            }
        ],
        [   q{S288c.I(+):27070-29557},
            {   name   => "S288c",
                chr    => "I",
                strand => "+",
                start  => 27070,
                end    => 29557,
            }
        ],
        [   q{I(+):90-150},
            {   chr    => "I",
                strand => "+",
                start  => 90,
                end    => 150,
            }
        ],
        [   q{S288c.I(-):190-200},
            {   name   => "S288c",
                chr    => "I",
                strand => "-",
                start  => 190,
                end    => 200,
            }
        ],
        [   q{I:1-100},
            {   chr   => "I",
                start => 1,
                end   => 100,
            }
        ],
        [   q{I:100},
            {   chr   => "I",
                start => 100,
                end   => 100,
            }
        ],
    );

    for my $i ( 0 .. $#data_fas_header ) {
        my ( $header, $expected ) = @{ $data_fas_header[$i] };
        my $result = App::RL::Common::decode_header($header);

        for my $key ( keys %{$expected} ) {
            is( $expected->{$key}, $result->{$key}, "fas decode $i" );
        }
        for my $key ( keys %{$result} ) {
            next if !defined $result->{$key};
            is( $expected->{$key}, $result->{$key}, "fas decode $i" );
        }

        is( $header,
            App::RL::Common::encode_header($expected),
            "fas encode expected $i"
        );
        is( $header,
            App::RL::Common::encode_header($result),
            "fas encode result $i"
        );
        ok( App::RL::Common::info_is_valid($result),   "result valid $i" );
        ok( App::RL::Common::info_is_valid($expected), "expected valid $i" );
    }
}

{
    print "#fa headers\n";

    my @data_fa_header = (
        [ q{S288c},                   { chr => "S288c", } ],
        [ q{S288c The baker's yeast}, { chr => "S288c", } ],
        [ q{1:-100},                  { chr => "1:-100", } ],
    );

    for my $i ( 0 .. $#data_fa_header ) {
        my ( $header, $expected ) = @{ $data_fa_header[$i] };
        my $result = App::RL::Common::decode_header($header);
        for my $key ( keys %{$expected} ) {
            is( $expected->{$key}, $result->{$key}, "fa decode $i" );
        }
    }
}

done_testing();
