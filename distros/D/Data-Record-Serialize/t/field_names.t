#!perl

use Test2::V0 qw[ :DEFAULT bag ];

use Data::Dumper;
use Data::Record::Serialize;

use Test::Lib;


subtest "unspecified" => sub {

    my $s;
    my $buf;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'ddump',
                sink   => 'stream',
                output => \$buf,
            );
        },
        'Data::Dumper -> buffer'
    ) or diag $@;


    $s->send( { long_a => 1, long_b => 2 } );

    my $exp_fields = bag {
        item 'long_a';
        item 'long_b';
        end();
    };

    is( $s->fields,        $exp_fields, 'input fields' );
    is( $s->output_fields, $exp_fields, 'output fields' );

    undef $s;

    my $VAR1;

    ok( lives { $VAR1 = eval $buf }, 'deserialize record' ) or diag $@;

    is( $VAR1, { long_a => 1, long_b => 2 }, 'both long_a & long_b' );

};

subtest "fields" => sub {

    my $s;
    my $buf;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'ddump',
                sink   => 'stream',
                output => \$buf,
                fields => [qw[ long_a long_b ]],
            );
        },
        'Data::Dumper -> buffer'
    ) or diag $@;

    my $exp_fields = bag {
        item 'long_a';
        item 'long_b';
        end();
    };

    is( $s->fields,        $exp_fields, 'input fields' );
    is( $s->output_fields, $exp_fields, 'output fields' );

    $s->send( { long_a => 1, long_b => 2 } );

    undef $s;

    my $VAR1;

    ok( lives { $VAR1 = eval $buf }, 'deserialize record' ) or diag $@;

    is( $VAR1, { long_a => 1, long_b => 2 }, 'both long_a & long_b' );

};

subtest "fields, subset" => sub {

    my $s;
    my $buf;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'ddump',
                sink   => 'stream',
                output => \$buf,
                fields => [qw[ long_b ]],
            );
        },
        'Data::Dumper -> buffer'
    ) or diag $@;


    is( $s->fields,        [qw( long_b )], 'input fields' );
    is( $s->output_fields, [qw( long_b )], 'output fields' );

    $s->send( { long_a => 1, long_b => 2 } );

    undef $s;

    my $VAR1;

    ok( lives { $VAR1 = eval $buf }, 'deserialize record' ) or diag $@;

    is( $VAR1, { long_b => 2 }, 'only long_b' );

};


subtest "rename" => sub {

    my $s;
    my $buf;

    ok(
        lives {
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

    is(
        $s->fields,
        bag {
            item 'long_a';
            item 'long_b';
            end();
        },
        'input fields'
    );

    is(
        $s->output_fields,
        bag {
            item 'long_b';
            item 'short_a';
        },
        'output fields',
    );

    $s->send( { long_a => 1, long_b => 2 } );

    undef $s;

    my $VAR1;

    ok( lives { $VAR1 = eval $buf }, 'deserialize record' ) or diag $@;

    is(
        $VAR1,
        { short_a => 1, long_b => 2 },
        'field name long_a renamed to short_a'
    );

};

done_testing;
