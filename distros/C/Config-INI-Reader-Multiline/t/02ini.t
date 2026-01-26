use strict;
use warnings;
use Test::More;

use Config::INI::Reader::Multiline;

my %test = (
    't/act.ini' => {
        general => {
            conferences => 'ye2003 fpw2004 apw2005 fpw2005 hpw2005 ipw2005 npw2005 ye2005 apw2006 fpw2006 ipw2006 npw2006',
            searchlimit => '20',
            cookie_name => 'act',
        }
    },
    't/continued.ini' => {
        _ => {
            klonk => 'zlonk',
            vronk => 'zlott',
        },
        glurpp => {
            zok              => 'plop kapow',
            zapeth           => 'eee_yow',
            '[clange] slosh' => 'ouch',
        },
    },
    't/comment.ini' => {
        'section1' => {
            'name1' => 'value1 extravalue1',
            'name2' => 'value2',
        },
        'section2' => {
            'name3' => 'value3',
        },
        section3 => {},
    },
    't/weird_continuations.ini' => {
        'flrbbbbb thunk' => {
            whap => 'z_zwap   glipp',
        },
        'blurp clank_est' => {
            bang_eth => 'ker_sploosh',
        },
    }
);

plan tests => scalar keys %test;

for my $ini ( sort keys %test ) {
    is_deeply( Config::INI::Reader::Multiline->read_file($ini),
        $test{$ini}, $ini );
}

