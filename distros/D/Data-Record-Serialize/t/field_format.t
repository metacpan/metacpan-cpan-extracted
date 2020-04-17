#!perl

use Test2::V0;

use Test::Lib;

use Data::Record::Serialize;

subtest "format fields" => sub {

    my ( $s, $buf );

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode        => 'ddump',
                output        => \$buf,
                format_fields => {
                    a => 'aAa: %s',
                    b => 'bBb: %s',
                    c => sub { qq(cCc: $_[0]) }
                },
            );
        },
        "constructor"
    ) or diag $@;

    $s->send( { a => 1, b => 2, c => 'nyuck nyuck', d => 'niagara falls' } );

    my $VAR1;

    ok( lives { $VAR1 = eval $buf }, 'deserialize record' ) or diag $@;

    is(
        $VAR1,
        {
            a => 'aAa: 1',
            b => 'bBb: 2',
            c => 'cCc: nyuck nyuck',
            d => 'niagara falls'
        },
        'properly formatted'
    );

};

subtest "format types" => sub {

    my ( $s, $buf );

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'ddump',
                output => \$buf,
                types  => {
                    a => 'N',
                    b => 'I',
                    c => 'S',
                },
                format_types => {
                    N => 'number: %s',
                    I => 'integer: %s',
                    S => sub { qq(string: $_[0]) },
                },
            );
        },
        "constructor"
    ) or diag $@;

    $s->send( { a => 1, b => 2, c => 3 } );

    my $VAR1;

    ok( lives { $VAR1 = eval $buf }, 'deserialize record' ) or diag $@;

    is(
        $VAR1,
        {
            a => 'number: 1',
            b => 'integer: 2',
            c => 'string: 3',
        },
        'properly formatted'
    );

};

subtest "format types w/o specifying them" => sub {

    my ( $s, $buf );

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode       => 'ddump',
                output       => \$buf,
                format_types => {
                    N => 'number: %s',
                    I => 'integer: %s',
                    S => sub { qq(string: $_[0]) },
                },
            );
        },
        "constructor"
    ) or diag $@;

    $s->send( { a => 1.1, b => 2, c => 'nyuck' } );

    my $VAR1;

    ok( lives { $VAR1 = eval $buf }, 'deserialize record' ) or diag $@;

    is(
        $VAR1,
        {
            a => 'number: 1.1',
            b => 'integer: 2',
            c => 'string: nyuck',
        },
        'properly formatted'
    );

};

subtest "format fields overrides types" => sub {

    my ( $s, $buf );

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'ddump',
                output => \$buf,
                types  => {
                    a => 'N',
                    b => 'I',
                    c => 'S',
                    d => 'S',
                },
                format_types => {
                    N => 'number: %s',
                    I => 'integer: %s',
                    S => sub { qq(string: $_[0]) },
                },
                format_fields => {
                    a => 'aAa: %s',
                    b => 'bBb: %s',
                    c => sub { qq(cCc: $_[0]) }
                },
            );
        },
        "constructor"
    ) or diag $@;

    $s->send( { a => 1, b => 2, c => 3, d => 4 } );

    my $VAR1;

    ok( lives { $VAR1 = eval $buf }, 'deserialize record' ) or diag $@;

    is(
        $VAR1,
        {
            a => 'aAa: 1',
            b => 'bBb: 2',
            c => 'cCc: 3',
            d => 'string: 4',
        },
        'properly formatted'
    );

};


done_testing;
