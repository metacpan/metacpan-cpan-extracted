package DBIx::ObjectMapper::Log;
use strict;
use warnings;
use Try::Tiny;

try {
    require Log::Any::Adapter;
    Log::Any::Adapter->import;
    my $min_level = 'info';

    if( $ENV{MAPPER_DEBUG} ) {
        $min_level = 'debug';
    }
    elsif( $ENV{HARNESS_ACTIVE} ) {
        $min_level = 'notice';
    }

    Log::Any::Adapter->set(
        { category => qr/^DBIx::ObjectMapper/ },
        'Dispatch',
        outputs => [
            [
                'Screen',
                min_level => $min_level,
                newline => 1,
            ]
        ],
        callbacks => sub {
            my %param = @_;
            return sprintf("[%s] %s", $param{level}, $param{message});
        }
    );
};

1;
