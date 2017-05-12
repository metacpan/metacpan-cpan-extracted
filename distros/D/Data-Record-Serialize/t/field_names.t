#!perl

use Test::More;
use Test::Fatal;

use Data::Dumper;
use Data::Record::Serialize;

use lib 't/lib';


subtest "unspecified" => sub {

    my $s;
    my $buf;


    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode => 'ddump',
                sink   => 'stream',
                output => \$buf,
            );
        },
        undef,
        'Data::Dumper -> buffer'
    );


    $s->send( { long_a => 1, long_b => 2 } );

    is_deeply( [ sort @{ $s->fields } ], [qw( long_a long_b )],
        'input fields' );
    is_deeply( [ sort @{ $s->output_fields } ],
        [qw( long_a long_b )], 'output fields' );

    undef $s;

    my $VAR1;

    is( exception { $VAR1 = eval $buf }, undef, 'deserialize record' );

    is_deeply( $VAR1, { long_a => 1, long_b => 2 }, 'both long_a & long_b' );

};


subtest "fields" => sub {

    my $s;
    my $buf;


    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode => 'ddump',
                sink   => 'stream',
                output => \$buf,
                fields => [qw[ long_a long_b ]],
            );
        },
        undef,
        'Data::Dumper -> buffer'
    );

    is_deeply( [ sort @{ $s->fields } ], [qw( long_a long_b )],
        'input fields' );
    is_deeply( [ sort @{ $s->output_fields } ],
        [qw( long_a long_b )], 'output fields' );

    $s->send( { long_a => 1, long_b => 2 } );


    undef $s;

    my $VAR1;

    is( exception { $VAR1 = eval $buf }, undef, 'deserialize record' );

    is_deeply( $VAR1, { long_a => 1, long_b => 2 }, 'both long_a & long_b' );

};

subtest "fields, subset" => sub {

    my $s;
    my $buf;


    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode => 'ddump',
                sink   => 'stream',
                output => \$buf,
                fields => [qw[ long_b ]],
            );
        },
        undef,
        'Data::Dumper -> buffer'
    );


    is_deeply( [ sort @{ $s->fields } ], [qw( long_b )], 'input fields' );
    is_deeply( [ sort @{ $s->output_fields } ],
        [qw( long_b )], 'output fields' );

    $s->send( { long_a => 1, long_b => 2 } );

    undef $s;

    my $VAR1;

    is( exception { $VAR1 = eval $buf }, undef, 'deserialize record' );

    is_deeply( $VAR1, { long_b => 2 }, 'only long_b' );

};


subtest "rename" => sub {

    my $s;
    my $buf;


    is(
        exception {
            $s = Data::Record::Serialize->new(
                encode        => 'ddump',
                sink          => 'stream',
                output        => \$buf,
                fields        => [qw[ long_a long_b ]],
                rename_fields => { long_a => 'short_a' },
            );
        },
        undef,
        'Data::Dumper -> buffer'
    );

    is_deeply( [ sort @{ $s->fields } ], [qw( long_a long_b )],
        'input fields' );
    is_deeply( [ sort @{ $s->output_fields } ],
        [qw( long_b short_a )], 'output fields' );

    $s->send( { long_a => 1, long_b => 2 } );

    undef $s;

    my $VAR1;

    is( exception { $VAR1 = eval $buf }, undef, 'deserialize record' );

    is_deeply(
        $VAR1,
        { short_a => 1, long_b => 2 },
        'field name long_a renamed to short_a'
    );

};

done_testing;
