use Data::Selector;
use Storable ();
use Test::More;
use Time::HiRes ();
use strict;
use warnings FATAL => 'all';

my $data_tree = {
    foo_1 => 'a',
    foo_2 => [ 'foo_2_1', [ 'foo_2_2', ], { foo_2_3 => 'b', }, ],
    foo_3 => {
        foo_3_1 => 'c',
        foo_3_2 => [ 'foo_3_2_1', ],
        foo_3_3 => { foo_3_3_1 => 'd', },
    },
    '+foo_4' => 'leading_plus',
    '-foo_4' => 'leading_hyphen',
    bar => bless( {}, 'Bar' ),
};

my @cases = (
    [ '*', $data_tree, 0.001, ],
    [ '*.*', $data_tree, 0.001, ],
    [ '-*', {}, 0.001, ],
    [
        '[foo_3,foo_1]', { map { ( $_, $data_tree->{$_}, ); } qw(foo_3 foo_1) },
        0.001,
    ],
    [
        'foo_1,-foo_1',
        { map { ( $_, $data_tree->{$_}, ); }
          qw(foo_2 foo_3 +foo_4 -foo_4 bar) },
        0.001,
    ],
    [ '-foo_1,foo_1', { foo_1 => 'a', }, 0.001, ],
    [
        'foo_2.[+-1,0],foo_3.foo_3_1',

        {
            foo_2 => [ 'foo_2_1', { foo_2_3 => 'b', }, ],
            foo_3 => { foo_3_1    => 'c', },
        },

        0.001,
    ],
    [ '(foo_*){1}', {}, 0.001, ],
    [ 'foo_2.asdf', { foo_2 => [], }, 0.001, ],
    [ 'foo_3.1',    { foo_3 => {}, }, 0.001, ],
    [ '-foo_3,*', $data_tree, 0.001, ],
    [
        '*,-foo_3',
        { map { ( $_, $data_tree->{$_}, ); }
          qw(foo_1 foo_2 +foo_4 -foo_4 bar) },
        0.001,
    ],
    [ 'foo_3,-*', {}, 0.001, ],
    [ '-*,foo_3', { map { ( $_, $data_tree->{$_}, ); } qw(foo_3) }, 0.001, ],
    [
        '-foo*,foo*',
        { map { ( $_, $data_tree->{$_}, ); } qw(foo_1 foo_2 foo_3) }, 0.001,
    ],
    [
        'foo*,-foo*', { map { ( $_, $data_tree->{$_}, ); }
          qw(+foo_4 -foo_4 bar) },
        0.001,
    ],
    [
        'foo_2.[1..2]', { foo_2 => [ [ 'foo_2_2', ], { foo_2_3 => 'b', }, ], },
        0.001,
    ],
    [
        'foo_2.[0..-1]',
        { foo_2 => [ 'foo_2_1', [ 'foo_2_2', ], { foo_2_3 => 'b', }, ], },
        0.001,
    ],
    [
        'foo_2.[0..-1].-foo_2_3',
        { foo_2 => [ 'foo_2_1', [ 'foo_2_2', ], {}, ], }, 0.001,
    ],
    [
        'foo_2.[0..-1].-0',
        { foo_2 => [ 'foo_2_1', [], { foo_2_3 => 'b', }, ], }, 0.001,
    ],
    [
        'foo_2*.0,foo_2.1', { foo_2 => [ 'foo_2_1', [ 'foo_2_2', ], ], }, 0.001,
    ],
    [ 'foo_2.0..0',  { foo_2 => [ 'foo_2_1', ], }, 0.001, ],
    [ 'foo_2.+0..0', { foo_2 => [ 'foo_2_1', ], }, 0.001, ],
    [
        'foo_2.-0..0', { foo_2 => [ [ 'foo_2_2', ], { foo_2_3 => 'b', }, ], },
        0.001,
    ],
    [ 'foo_2.-1..-1', { foo_2 => [ 'foo_2_1', ], }, 0.001, ],
    [ 'foo_2.+-1..-1', { foo_2 => [ { foo_2_3 => 'b', }, ], }, 0.001, ],
    [ 'foo_2.--1..-1', { foo_2 => [ 'foo_2_1', [ 'foo_2_2', ], ], }, 0.001, ],
    [ '++foo_4', { '+foo_4' => 'leading_plus', }, 0.001, ],
    [
        '--foo_4',
        do {
            my $data_tree_temp = Storable::dclone($data_tree);
            delete $data_tree_temp->{'-foo_4'};
            $data_tree_temp;
        },
        0.001,
    ],
    [ '+-foo_4', { '-foo_4' => 'leading_hyphen', }, 0.001, ],
    [
        '-+foo_4',
        do {
            my $data_tree_temp = Storable::dclone($data_tree);
            delete $data_tree_temp->{'+foo_4'};
            $data_tree_temp;
        },
        0.001,
    ],

    # include 0, 1, 2, & 3
    [ 'foo_2.0',  { foo_2 => [ 'foo_2_1', ], }, 0.001, ],
    [ 'foo_2.+0', { foo_2 => [ 'foo_2_1', ], }, 0.001, ],
    [ 'foo_2.1',  { foo_2 => [ [ 'foo_2_2', ], ], }, 0.001, ],
    [ 'foo_2.+1', { foo_2 => [ [ 'foo_2_2', ], ], }, 0.001, ],
    [ 'foo_2.2',  { foo_2 => [ { foo_2_3 => 'b', }, ], }, 0.001, ],
    [ 'foo_2.+2', { foo_2 => [ { foo_2_3 => 'b', }, ], }, 0.001, ],
    [ 'foo_2.3',  { foo_2 => [], }, 0.001, ],
    [ 'foo_2.+3', { foo_2 => [], }, 0.001, ],

    # exclude 0, 1, 2 & 3
    [
        'foo_2.-0', { foo_2 => [ [ 'foo_2_2', ], { foo_2_3 => 'b', }, ], },
        0.001,
    ],
    [ 'foo_2.-1', { foo_2 => [ 'foo_2_1', { foo_2_3 => 'b', }, ], }, 0.001, ],
    [ 'foo_2.-2', { foo_2 => [ 'foo_2_1', [ 'foo_2_2', ], ], }, 0.001, ],
    [
        'foo_2.-3',
        { foo_2 => [ 'foo_2_1', [ 'foo_2_2', ], { foo_2_3 => 'b', }, ], },
        0.001,
    ],

    # include -0, -1, -2, -3, & -4
    [ 'foo_2.+-0', { foo_2 => [ 'foo_2_1', ], }, 0.001, ],
    [ 'foo_2.+-1', { foo_2 => [ { foo_2_3 => 'b', }, ], }, 0.001, ],
    [ 'foo_2.+-2', { foo_2 => [ [ 'foo_2_2', ], ], }, 0.001, ],
    [ 'foo_2.+-3', { foo_2 => [ 'foo_2_1', ], }, 0.001, ],
    [ 'foo_2.+-4', { foo_2 => [], }, 0.001, ],

    # exclude -0, -1, -2, -3, & -4
    [
        'foo_2.--0', { foo_2 => [ [ 'foo_2_2', ], { foo_2_3 => 'b', }, ], },
        0.001,
    ],
    [ 'foo_2.--1', { foo_2 => [ 'foo_2_1', [ 'foo_2_2', ], ], }, 0.001, ],
    [ 'foo_2.--2', { foo_2 => [ 'foo_2_1', { foo_2_3 => 'b', }, ], }, 0.001, ],
    [
        'foo_2.--3', { foo_2 => [ [ 'foo_2_2', ], { foo_2_3 => 'b', }, ], },
        0.001,
    ],
    [
        'foo_2.--4',
        { foo_2 => [ 'foo_2_1', [ 'foo_2_2', ], { foo_2_3 => 'b', }, ], },
        0.001,
    ],

    # included and excluded negative array subscripts involved in
    # selector tree merging
    [ 'foo_2.-*,foo_2.+-1.bar', { foo_2 => [ {}, ], }, 0.001, ],
    [
        'foo_2.*,foo_2.--1', { foo_2 => [ 'foo_2_1', [ 'foo_2_2', ], ], },
        0.001,
    ],

    [
        '*foo_4', { '+foo_4' => 'leading_plus', '-foo_4' => 'leading_hyphen', },
        0.001,
    ],
    [ '+non-existent',       {}, 0.001, ],
    [ '+non-existent,-foo*', {}, 0.001, ],
    [ '-non-existent', $data_tree, 0.001, ],
    [ {}, $data_tree, 0.001, 'empty selector tree', ],
);

for (@cases) {
    my ( $selector, $data_tree_expected, $elasped_expected, ) = @{$_};
    my $desc            = $_->[3] || $selector;
    my $before          = Time::HiRes::time;
    my $data_tree_local = Storable::dclone($data_tree);
    my $selector_tree =
      ref $selector
      ? $selector
      : Data::Selector->parse_string( { selector_string => $selector, } );
    Data::Selector->apply_tree(
        {
            selector_tree => $selector_tree,
            data_tree     => $data_tree_local,
        }
    );
    my $elapsed_got = Time::HiRes::time - $before;
    is_deeply( $data_tree_local, $data_tree_expected, "$desc applied" );
    cmp_ok( $elapsed_got, '<', $elasped_expected, "$desc is fast enough" );
}

done_testing;
