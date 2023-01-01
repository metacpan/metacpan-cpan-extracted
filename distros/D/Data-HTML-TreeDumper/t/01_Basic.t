use strict;
use Test::More;
use Test::More::UTF8;
use YAML::Syck qw(Load LoadFile Dump DumpFile);
use FindBin::libs;
use Data::HTML::TreeDumper;
use open ':std' => ( $^O eq 'MSWin32' ? ':locale' : ':utf8' );

my $td = Data::HTML::TreeDumper->new();

subtest 'Scalar' => sub {
    is( $td->dump(undef), '<span class="trdValue">[undef]</span>', 'undef' );
    is( $td->dump(0),     '<span class="trdValue">0</span>',       'num:0' );
    is( $td->dump(1),     '<span class="trdValue">1</span>',       'num:1' );
    is( $td->dump(10),    '<span class="trdValue">10</span>',      'num:10' );
    is( $td->dump(''),    '<span class="trdValue"></span>',        'str:blank' );
    is( $td->dump('A'),   '<span class="trdValue">A</span>',       'str:A' );
    is( $td->dump('ABC'), '<span class="trdValue">ABC</span>',     'str:ABC' );
};

subtest 'ScalarRef' => sub {
    is( $td->dump( \0 ),     '<span class="trdValue">0</span>',   'num:0' );
    is( $td->dump( \1 ),     '<span class="trdValue">1</span>',   'num:1' );
    is( $td->dump( \10 ),    '<span class="trdValue">10</span>',  'num:10' );
    is( $td->dump( \'' ),    '<span class="trdValue"></span>',    'str:blank' );
    is( $td->dump( \'A' ),   '<span class="trdValue">A</span>',   'str:A' );
    is( $td->dump( \'ABC' ), '<span class="trdValue">ABC</span>', 'str:ABC' );
};

subtest 'ArrayRef' => sub {
    map { is( $td->dump( $_->{input}, $_->{name} ), $_->{expected}, $_->{name} ); } (
        {   input    => [],
            expected => '<details>' . '<summary class="trdKey">blank</summary>' . '</details>',
            name     => 'blank'
        },
        {   input    => [ 0, 1, 2 ],
            expected => '<details>'
                . '<summary class="trdKey">[0,1,2]</summary>'
                . '<ol class="trdOL" start="0">'
                . '<li><span class="trdValue">0</span></li>'
                . '<li><span class="trdValue">1</span></li>'
                . '<li><span class="trdValue">2</span></li>'
                . '</ol></details>',
            name => '[0,1,2]'
        },
        {   input    => [ 'A', 'B', 'C' ],
            expected => '<details>'
                . '<summary class="trdKey">[A,B,C]</summary>'
                . '<ol class="trdOL" start="0">'
                . '<li><span class="trdValue">A</span></li>'
                . '<li><span class="trdValue">B</span></li>'
                . '<li><span class="trdValue">C</span></li>'
                . '</ol></details>',
            name => '[A,B,C]'
        },
    );
};

subtest 'HashRef' => sub {
    map { is( $td->dump( $_->{input}, $_->{name} ), $_->{expected}, $_->{name} ); } (
        {   input    => {},
            expected => '<details>' . '<summary class="trdKey">blank</summary>' . '</details>',
            name     => 'blank'
        },
        {   input    => { A => 0, B => 1, C => 2 },
            expected => '<details>'
                . '<summary class="trdKey">[A=&gt;0,B=&gt;1,C=&gt;2]</summary>'
                . '<ul class="trdUL">'
                . '<li><span class="trdKey">A</span>: <span class="trdValue">0</span></li>'
                . '<li><span class="trdKey">B</span>: <span class="trdValue">1</span></li>'
                . '<li><span class="trdKey">C</span>: <span class="trdValue">2</span></li>'
                . '</ul>'
                . '</details>',
            name => '[A=>0,B=>1,C=>2]'
        },
    );
};

subtest 'ArrayOfArray' => sub {
    map { is( $td->dump( $_->{input}, $_->{name} ), $_->{expected}, $_->{name} ); } (
        {   input    => [ [], [], [] ],
            expected => '<details>'
                . '<summary class="trdKey">blank array</summary>'
                . '<ol class="trdOL" start="0">'
                . '<li><details>'
                . '<summary class="trdKey">ARRAY</summary>'
                . '</details></li>'
                . '<li><details>'
                . '<summary class="trdKey">ARRAY</summary>'
                . '</details></li>'
                . '<li><details>'
                . '<summary class="trdKey">ARRAY</summary>'
                . '</details></li>'
                . '</ol></details>',
            name => 'blank array'
        },
        {   input    => [ [undef], [ 0, 1 ], [ 2, 3, 4 ] ],
            expected => '<details>'
                . '<summary class="trdKey">jagged array</summary>'
                . '<ol class="trdOL" start="0">'
                . '<li><details>'
                . '<summary class="trdKey">ARRAY</summary>'
                . '<ol class="trdOL" start="0">'
                . '<li><span class="trdValue">[undef]</span></li>'
                . '</ol></details></li>'
                . '<li><details>'
                . '<summary class="trdKey">ARRAY</summary>'
                . '<ol class="trdOL" start="0">'
                . '<li><span class="trdValue">0</span></li>'
                . '<li><span class="trdValue">1</span></li>'
                . '</ol></details></li>'
                . '<li><details>'
                . '<summary class="trdKey">ARRAY</summary>'
                . '<ol class="trdOL" start="0">'
                . '<li><span class="trdValue">2</span></li>'
                . '<li><span class="trdValue">3</span></li>'
                . '<li><span class="trdValue">4</span></li>'
                . '</ol></details></li>'
                . '</ol></details>',
            name => 'jagged array'
        },
    );
};

subtest 'HashOfHash' => sub {
    map { is( $td->dump( $_->{input}, $_->{name} ), $_->{expected}, $_->{name} ); } (
        {   input => {
                a => {
                    c => { g => { o => undef }, h => { p => 0 } },
                    d => { i => { q => 1 },     j => { r => 2 } },
                },
                b => {
                    e => { k   => { 's' => 3 }, l => { t => 4 } },
                    f => { 'm' => { u   => 5 }, n => { v => 6 } }
                },
            },
            expected => '<details>'
                . '<summary class="trdKey">hash of hash</summary>'
                . '<ul class="trdUL">'
                . '<li><details>'
                . '<summary class="trdKey">a</summary>'
                . '<ul class="trdUL">'
                . '<li><details>'
                . '<summary class="trdKey">c</summary>'
                . '<ul class="trdUL">'
                . '<li><details>'
                . '<summary class="trdKey">g</summary>'
                . '<ul class="trdUL">'
                . '<li><span class="trdKey">o</span>: <span class="trdValue">[undef]</span></li>'
                . '</ul></details></li>'
                . '<li><details>'
                . '<summary class="trdKey">h</summary>'
                . '<ul class="trdUL">'
                . '<li><span class="trdKey">p</span>: <span class="trdValue">0</span></li>'
                . '</ul></details></li>'
                . '</ul></details></li>'
                . '<li><details>'
                . '<summary class="trdKey">d</summary>'
                . '<ul class="trdUL">'
                . '<li><details>'
                . '<summary class="trdKey">i</summary>'
                . '<ul class="trdUL">'
                . '<li><span class="trdKey">q</span>: <span class="trdValue">1</span></li>'
                . '</ul></details></li>'
                . '<li><details>'
                . '<summary class="trdKey">j</summary>'
                . '<ul class="trdUL">'
                . '<li><span class="trdKey">r</span>: <span class="trdValue">2</span></li>'
                . '</ul></details></li>'
                . '</ul></details></li>'
                . '</ul></details></li>'
                . '<li><details>'
                . '<summary class="trdKey">b</summary>'
                . '<ul class="trdUL">'
                . '<li><details>'
                . '<summary class="trdKey">e</summary>'
                . '<ul class="trdUL">'
                . '<li><details>'
                . '<summary class="trdKey">k</summary>'
                . '<ul class="trdUL">'
                . '<li><span class="trdKey">s</span>: <span class="trdValue">3</span></li>'
                . '</ul></details></li>'
                . '<li><details>'
                . '<summary class="trdKey">l</summary>'
                . '<ul class="trdUL">'
                . '<li><span class="trdKey">t</span>: <span class="trdValue">4</span></li>'
                . '</ul></details></li>'
                . '</ul></details></li>'
                . '<li><details>'
                . '<summary class="trdKey">f</summary>'
                . '<ul class="trdUL">'
                . '<li><details>'
                . '<summary class="trdKey">m</summary>'
                . '<ul class="trdUL">'
                . '<li><span class="trdKey">u</span>: <span class="trdValue">5</span></li>'
                . '</ul></details></li>'
                . '<li><details>'
                . '<summary class="trdKey">n</summary>'
                . '<ul class="trdUL">'
                . '<li><span class="trdKey">v</span>: <span class="trdValue">6</span></li>'
                . '</ul></details></li>'
                . '</ul></details></li>'
                . '</ul></details></li>'
                . '</ul></details>',
            name => 'hash of hash'
        },
    );
};

subtest 'Depth3' => sub {
    my $td_depth3 = Data::HTML::TreeDumper->new( MaxDepth => 3 );
    map { is( $td_depth3->dump( $_->{input}, $_->{name} ), $_->{expected}, $_->{name} ); } (
        {   input => [ 1, [ 2, [ 3, [ 4, [ 5, [ 6, [ 7, [ 8, [ 9, [ 10, undef ] ] ] ] ] ] ] ] ] ],
            expected => '<details>'
                . '<summary class="trdKey">Array</summary>'
                . '<ol class="trdOL" start="0">'
                . '<li><span class="trdValue">1</span></li>'
                . '<li><details>'
                . '<summary class="trdKey">ARRAY</summary>'
                . '<ol class="trdOL" start="0">'
                . '<li><span class="trdValue">2</span></li>'
                . '<li><details>'
                . '<summary class="trdKey">ARRAY</summary>'
                . '<ol class="trdOL" start="0">'
                . '<li><span class="trdValue">3</span></li>'
                . '<li><span class="trdKey">ARRAY</span>: <span class="trdValue">[...]</span></li>'
                . '</ol></details></li>'
                . '</ol></details></li>'
                . '</ol></details>',
            name => 'Array'
        },
        {   input => {
                k => 1,
                v => {
                    k => 2,
                    v => {
                        k => 3,
                        v => {
                            k => 4,
                            v => {
                                k => 5,
                                v => {
                                    k => 6,
                                    v => {
                                        k => 7,
                                        v => {
                                            k => 8,
                                            v => { k => 9, v => { k => 10, v => undef } }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            expected => '<details>'
                . '<summary class="trdKey">Hash</summary>'
                . '<ul class="trdUL">'
                . '<li><span class="trdKey">k</span>: <span class="trdValue">1</span></li>'
                . '<li><details>'
                . '<summary class="trdKey">v</summary>'
                . '<ul class="trdUL">'
                . '<li><span class="trdKey">k</span>: <span class="trdValue">2</span></li>'
                . '<li><details>'
                . '<summary class="trdKey">v</summary>'
                . '<ul class="trdUL">'
                . '<li><span class="trdKey">k</span>: <span class="trdValue">3</span></li>'
                . '<li><span class="trdKey">v</span>: <span class="trdValue">{...}</span></li>'
                . '</ul></details></li>'
                . '</ul></details></li>'
                . '</ul></details>',
            name => 'Hash'
        },
    );
};

done_testing;
