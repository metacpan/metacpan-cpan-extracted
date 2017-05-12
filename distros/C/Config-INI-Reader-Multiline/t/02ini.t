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
            zok    => 'plop kapow',
            zapeth => 'eee_yow',
        },
    },
);

plan tests => scalar keys %test;

for my $ini ( sort keys %test ) {
    is_deeply( Config::INI::Reader::Multiline->read_file($ini),
        $test{$ini}, $ini );
}

