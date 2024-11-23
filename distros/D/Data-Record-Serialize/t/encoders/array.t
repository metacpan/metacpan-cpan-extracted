#!perl

use Test2::V0;

use Test::Lib;

use My::Test::Util -all;

use Data::Record::Serialize;

my $s;

my @output;
ok(
    lives {
        $s = Data::Record::Serialize->new(
            encode => 'array',
            sink   => 'array',
            output => \@output,
            fields => [ 'integer', 'number', 'string1', 'string2', 'bool' ],
        );
    },
    'constructor',
) or diag $@;

# prime types
$s->send( {
    integer => 1,
    number  => 2.2,
    string1 => 'string',
    string2 => 'nyuck nyuck',
} );

# read and make sure round trip types are correct
is(
    $output[0],
    bag {
        item $_ for 'integer', 'number', 'string1', 'string2', 'bool';
        end;
    },
    'fields',
);

is(
    $output[1],
    bag {
        item $_ for 1, 2.2, 'string', 'nyuck nyuck', undef;
        end;
    },
    'values',
);

done_testing;
