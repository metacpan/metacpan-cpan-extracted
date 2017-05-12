use Test::Base;
use utf8;

plan tests => 1 + 1 * blocks;

use_ok("Acme::Shukugawa::Atom");


sub translate {
    Acme::Shukugawa::Atom->translate(shift);
}

filters {
    input => 'translate',
};

run_is;

__DATA__

===
--- input: 照明
--- expected: メイショー
