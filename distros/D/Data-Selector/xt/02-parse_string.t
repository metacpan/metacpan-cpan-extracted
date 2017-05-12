use Data::Selector;
use Test::More;
use Time::HiRes ();
use strict;
use warnings FATAL => 'all';

my @cases = (
    [ 'foo',    { '+foo' => { _order_ => 1, }, }, 500e-6, ],
    [ '[+foo]', { '+foo' => { _order_ => 1, }, }, 500e-6, ],
    [
        'foo.bar',
        { '+foo' => { _order_ => 1, '+bar' => { _order_ => 2, }, }, }, 500e-6,
    ],
    [
        'abc.def.ghi.jkl.[mno,pqr]',
        {
            '+abc' => {
                _order_ => 1,
                '+def'  => {
                    _order_ => 2,
                    '+ghi'  => {
                        _order_ => 3,
                        '+jkl'  => {
                            _order_ => 4,
                            '+mno'  => { _order_ => 5, },
                            '+pqr'  => { _order_ => 6, },
                        },
                    },
                },
            },
        },
        0.001,
    ],
    [
        'abc.def.[ghi,jkl].mno.pqr',
        {
            '+abc' => {
                _order_ => 1,
                '+def'  => {
                    _order_ => 2,
                    '+ghi'  => {
                        _order_ => 3,
                        '+mno'  => {
                            _order_ => 5,
                            '+pqr'  => { _order_ => 7, },
                        },
                    },
                    '+jkl' => {
                        _order_ => 4,
                        '+mno'  => {
                            _order_ => 6,
                            '+pqr'  => { _order_ => 8, },
                        },
                    },

                },
            },
        },
        0.001,
    ],
    [
        '[abc,def].ghi.jkl.mno.pqr',
        {
            '+abc' => {
                _order_ => 1,
                '+ghi'  => {
                    _order_ => 3,
                    '+jkl'  => {
                        _order_ => 5,
                        '+mno'  => {
                            _order_ => 7,
                            '+pqr'  => { _order_ => 9, },
                        },
                    },
                },
            },
            '+def' => {
                _order_ => 2,
                '+ghi'  => {
                    _order_ => 4,
                    '+jkl'  => {
                        _order_ => 6,
                        '+mno'  => {
                            _order_ => 8,
                            '+pqr'  => { _order_ => 10, },
                        },
                    },
                },
            },
        },
        0.001,
    ],
    [
        'abc.def.[ghi].[jkl].mno.pqr',
        {
            '+abc' => {
                _order_ => 1,
                '+def'  => {
                    _order_ => 2,
                    '+ghi'  => {
                        _order_ => 3,
                        '+jkl'  => {
                            _order_ => 4,
                            '+mno'  => {
                                _order_ => 5,
                                '+pqr'  => { _order_ => 6, },
                            },
                        },
                    },
                },
            },
        },
        0.001,
    ],
    [
        'foo,abc.def.[ghi,jkl].mno.pqr,bar.[baz1,baz2].woohoo',
        {
            '+foo' => { _order_ => 1, },
            '+abc' => {
                _order_ => 2,
                '+def'  => {
                    _order_ => 4,
                    '+ghi'  => {
                        _order_ => 7,
                        '+mno'  => {
                            _order_ => 11,
                            '+pqr'  => { _order_ => 13, },
                        },
                    },
                    '+jkl' => {
                        _order_ => 8,
                        '+mno'  => {
                            _order_ => 12,
                            '+pqr'  => { _order_ => 14, },
                        },
                    },

                },
            },
            '+bar' => {
                _order_ => 3,
                '+baz1' => {
                    _order_   => 5,
                    '+woohoo' => { _order_ => 9, },
                },
                '+baz2' => {
                    _order_   => 6,
                    '+woohoo' => { _order_ => 10, },
                },
            },
        },
        0.001,
    ],
    [
        'foo_1_1.[foo_1_2]'
          . ',foo_2_1.foo_2_2.[foo_2_3.[foo_2_4,foo_2_5].[foo_2_8]]'
          . ',foo_3_1',
        {
            '+foo_2_1' => {
                _order_    => 2,
                '+foo_2_2' => {
                    _order_    => 5,
                    '+foo_2_3' => {
                        _order_    => 6,
                        '+foo_2_5' => {
                            _order_    => 8,
                            '+foo_2_8' => { _order_ => 10, },
                        },
                        '+foo_2_4' => {
                            _order_    => 7,
                            '+foo_2_8' => { _order_ => 9, },
                        },
                    },
                },
            },
            '+foo_1_1' => {
                _order_    => 1,
                '+foo_1_2' => { _order_ => 4, },
            },
            '+foo_3_1' => { _order_ => 3, },
        },
        0.001,
    ],
    [ '-foo',     { '-foo' => { _order_ => 1, }, }, 500e-6, ],
    [ 'foo,-foo', { '-foo' => { _order_ => 2, }, }, 500e-6, ],
    [ '-foo,foo', { '+foo' => { _order_ => 2, }, }, 500e-6, ],
    [
        'foo.bar.-baz,foo',
        {
            '+foo' => {
                _order_ => 2,
                '+bar'  => {
                    _order_ => 3,
                    '-baz'  => { _order_ => 4, },
                },
            },
        },
        500e-6,
    ],
    [ 'foo.bar.-baz,-foo', { '-foo' => { _order_ => 2, }, }, 500e-6, ],
    [
        '1..3.foo',
        {
            '+1..3' => {
                '+foo'    => { '_order_' => 2, },
                '_order_' => 1,
            }
        },
        500e-6,
    ],
    [
        '0..-5.foo',
        {
            '+0..-5' => {
                '+foo'    => { '_order_' => 2, },
                '_order_' => 1,
            }
        },
        500e-6,
    ],
    [
        '$all,0..-5.foo',
        {
            '+0..-5' => {
                '+foo'    => { '_order_' => 3, },
                '_order_' => 2,
            },
            '+*' => { '_order_' => 1, },
        },
        500e-6,
    ],
    [
        '$zero,0..-5.foo',
        {
            '+0..-5' => {
                '+foo'    => { '_order_' => 3, },
                '_order_' => 2,
            },
            '+0' => { '_order_' => 1, },
        },
        500e-6,
    ],
    [
        '$all,$zero',
        {
            '+*' => { '_order_' => 1, },
            '+0' => { '_order_' => 2, },
        },
        500e-6,
    ],

    # include +foo and -foo
    [ '++foo', { '++foo' => { _order_ => 1, }, }, 500e-6, ],
    [ '+-foo', { '+-foo' => { _order_ => 1, }, }, 500e-6, ],

    #exclude +foo and -foo
    [ '-+foo', { '-+foo' => { _order_ => 1, }, }, 500e-6, ],
    [ '--foo', { '--foo' => { _order_ => 1, }, }, 500e-6, ],

    # include and exclude 2
    [ '2',  { '+2' => { _order_ => 1, }, }, 500e-6, ],
    [ '+2', { '+2' => { _order_ => 1, }, }, 500e-6, ],
    [ '-2', { '-2' => { _order_ => 1, }, }, 500e-6, ],

    # include and exclude -2
    [ '+-2', { '+-2' => { _order_ => 1, }, }, 500e-6, ],
    [ '--2', { '--2' => { _order_ => 1, }, }, 500e-6, ],

    # include and exclude +2 which are not interpreted
    # numerically so they don't work as one might expect
    # for arrays - use 2 instead of +2.
    [ '++2', { '++2' => { _order_ => 1, }, }, 500e-6, ],
    [ '-+2', { '-+2' => { _order_ => 1, }, }, 500e-6, ],
);
push(
    @cases,
    [
        join( ',', map { $cases[8]->[0]; } 1 .. 20, ),
        {
            '+foo_2_1' => {
                _order_    => 59,
                '+foo_2_2' => {
                    _order_    => 100,
                    '+foo_2_3' => {
                        _order_    => 120,
                        '+foo_2_5' => {
                            _order_    => 160,
                            '+foo_2_8' => { _order_ => 200, },
                        },
                        '+foo_2_4' => {
                            _order_    => 159,
                            '+foo_2_8' => { _order_ => 199, },
                        },
                    },
                },
            },
            '+foo_1_1' => {
                _order_    => 58,
                '+foo_1_2' => { _order_ => 99, },
            },
            '+foo_3_1' => { _order_ => 60, },
        },
        0.010,
        'too big',
    ],
);

for (@cases) {
    my ( $selector_string, $selector_tree_expected, $elasped_expected, ) =
      @{$_};
    my $desc              = $_->[3] || $selector_string;
    my $before            = Time::HiRes::time;
    my $selector_tree_got = Data::Selector->parse_string(
        {
            selector_string => $selector_string,
            named_selectors => {
                '$all'  => '*',
                '$zero' => 0,
            },
        }
    );
    my $elapsed_got = Time::HiRes::time - $before;
    is_deeply( $selector_tree_got, $selector_tree_expected, "$desc parsed" );
    cmp_ok( $elapsed_got, '<', $elasped_expected, "$desc is fast enough" );
}

done_testing;
