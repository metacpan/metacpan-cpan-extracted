#!perl

use Test2::V0 qw[ :DEFAULT bag ];

use Data::Dumper;
use Data::Record::Serialize;

use Test::Lib;

note
  "Test names encode presence/value of  fields (Y/N/all), types(Y/N), default_type(Y/N)";

subtest "N, N, N" => sub {
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new( encode => 'types_nis', );
        },
        'construct'
    ) or note $@;

    $s->send( { a => 1, b => 'boo', c => 2.2 } );

    is(
        $s->fields,
        bag {
            item 'a';
            item 'b';
            item 'c';
            end;
        },
        ,
        'input fields'
    );
    is(
        $s->output_fields,
        bag {
            item 'a';
            item 'b';
            item 'c';
            end;
        },
        'output fields'
    );

    is( $s->output_types, { a => 'I', b => 'S', c => 'N' }, 'output types' );
};

subtest "all, N, N" => sub {
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'types_nis',
                fields => 'all'
            );
        },
        'construct'
    ) or note $@;

    $s->send( { a => 1, b => 'boo', c => 2.2 } );

    is(
        $s->fields,
        bag {
            item 'a';
            item 'b';
            item 'c';
            end;
        },
        ,
        'input fields'
    );
    is(
        $s->output_fields,
        bag {
            item 'a';
            item 'b';
            item 'c';
            end;
        },
        'output fields'
    );

    is( $s->output_types, { a => 'I', b => 'S', c => 'N' }, 'output types' );
};


subtest "N, N, Y" => sub {
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode       => 'types_nis',
                default_type => 'S'
            );
        },
        'construct'
    ) or note $@;

    $s->send( { a => 1, b => 'boo', c => 2.2 } );

    is(
        $s->fields,
        bag {
            item 'a';
            item 'b';
            item 'c';
            end;
        },
        ,
        'input fields'
    );
    is(
        $s->output_fields,
        bag {
            item 'a';
            item 'b';
            item 'c';
            end;
        },
        'output fields'
    );

    is( $s->output_types, { a => 'S', b => 'S', c => 'S' }, 'output types' );
};

subtest "all, N, Y" => sub {
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode       => 'types_nis',
                default_type => 'S',
                fields       => 'all'
            );
        },
        'construct'
    ) or note $@;

    $s->send( { a => 1, b => 'boo', c => 2.2 } );

    is(
        $s->fields,
        bag {
            item 'a';
            item 'b';
            item 'c';
            end;
        },
        ,
        'input fields'
    );
    is(
        $s->output_fields,
        bag {
            item 'a';
            item 'b';
            item 'c';
            end;
        },
        'output fields'
    );

    is( $s->output_types, { a => 'S', b => 'S', c => 'S' }, 'output types' );
};

subtest "Y, N, N" => sub {
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'types_nis',
                fields => [ 'a', 'b' ] );
        },
        'construct'
    ) or note $@;

    $s->send( { a => 1, b => 'boo', c => 2.2 } );

    is(
        $s->fields,
        bag {
            item 'a';
            item 'b';
            end;
        },
        ,
        'input fields'
    );
    is(
        $s->output_fields,
        bag {
            item 'a';
            item 'b';
            end;
        },
        'output fields'
    );

    is( $s->output_types, { a => 'I', b => 'S' }, 'output types' );
};

subtest "Y, Y, N" => sub {
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'types_nis',
                fields => [ 'a', 'c' ],
                types  => { a => 'S' } );
        },
        'construct'
    ) or note $@;

    $s->send( { a => 1, b => 'boo', c => 2.2 } );

    is(
        $s->fields,
        bag {
            item 'a';
            item 'c';
            end;
        },
        ,
        'input fields'
    );
    is(
        $s->output_fields,
        bag {
            item 'a';
            item 'c';
            end;
        },
        'output fields'
    );

    is( $s->output_types, { a => 'S', c => 'N' }, 'output types' );
};

subtest "Y, Y, Y" => sub {
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode       => 'types_nis',
                fields       => [ 'a', 'b' ],
                types        => { a => 'S' },
                default_type => 'I'
            );
        },
        'construct'
    ) or note $@;

    $s->send( { a => 1, b => 'boo', c => 2.2 } );

    is(
        $s->fields,
        bag {
            item 'a';
            item 'b';
            end;
        },
        ,
        'input fields'
    );
    is(
        $s->output_fields,
        bag {
            item 'a';
            item 'b';
            end;
        },
        'output fields'
    );

    is( $s->output_types, { a => 'S', b => 'I' }, 'output types' );
};

subtest "all, Y, N" => sub {
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'types_nis',
                fields => 'all',
                types  => { a => 'S' },
            );
        },
        'construct'
    ) or note $@;

    $s->send( { a => 1, b => 'boo', c => 2.2 } );

    is(
        $s->fields,
        bag {
            item 'a';
            item 'b';
            item 'c';
            end;
        },
        ,
        'input fields'
    );
    is(
        $s->output_fields,
        bag {
            item 'a';
            item 'b';
            item 'c';
            end;
        },
        'output fields'
    );

    is( $s->output_types, { a => 'S', b => 'S', c => 'N' }, 'output types' );
};

subtest "all, Y, Y" => sub {
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode       => 'types_nis',
                fields       => 'all',
                types        => { a => 'S' },
                default_type => 'I'
            );
        },
        'construct'
    ) or note $@;

    $s->send( { a => 1, b => 'boo', c => 2.2 } );

    is(
        $s->fields,
        bag {
            item 'a';
            item 'b';
            item 'c';
            end;
        },
        ,
        'input fields'
    );
    is(
        $s->output_fields,
        bag {
            item 'a';
            item 'b';
            item 'c';
            end;
        },
        'output fields'
    );

    is( $s->output_types, { a => 'S', b => 'I', c => 'I' }, 'output types' );
};

subtest "N, Y, Y" => sub {
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode       => 'types_nis',
                types        => { a => 'S' },
                default_type => 'I'
            );
        },
        'construct'
    ) or note $@;

    $s->send( { a => 1, b => 'boo', c => 2.2 } );

    is( $s->fields,        ['a'], 'input fields' );
    is( $s->output_fields, ['a'], 'output fields' );

    is( $s->output_types, { a => 'S' }, 'output types' );
};

subtest "N, Y, N" => sub {
    my $s;

    ok(
        lives {
            $s = Data::Record::Serialize->new(
                encode => 'types_nis',
                types  => { a => 'S' },
            );
        },
        'construct'
    ) or note $@;

    $s->send( { a => 1, b => 'boo', c => 2.2 } );

    is( $s->fields,        ['a'], 'input fields' );
    is( $s->output_fields, ['a'], 'output fields' );

    is( $s->output_types, { a => 'S' }, 'output types' );
};

subtest "field order" => sub {

    subtest "<fields>" => sub {

        my $s;

        ok(
            lives {
                $s = Data::Record::Serialize->new(
                    encode => 'types_nis',
                    fields => [ 'c', 'b', 'a' ],
                );
            },
            'construct'
        ) or note $@;

        $s->send( { a => 1, b => 'boo', c => 2.2 } );

        is( $s->output_fields, [ 'c', 'b', 'a' ], 'output fields' );

    };

    subtest "<types>" => sub {

        my $s;

        ok(
            lives {
                $s = Data::Record::Serialize->new(
                    encode => 'types_nis',
                    types => [ 'c' => 'N', 'b' => 'I', 'a' => 'S' ],
                );
            },
            'construct'
        ) or note $@;

        $s->send( { a => 1, b => 'boo', c => 2.2 } );

        is( $s->fields,        [ 'c', 'b', 'a' ], 'input fields' );

        is( $s->output_types, { c => 'N', 'b' => 'I', a => 'S' }, 'output types' );
        is( $s->output_fields, [ 'c', 'b', 'a' ], 'output fields' );
    };

};

done_testing;

