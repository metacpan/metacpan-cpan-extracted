use strict;
use warnings;
use utf8;
use Test::More 0.98;
use Const::Common::Generator;

is(Const::Common::Generator->generate(
    package => 'Hoge::Piyo',
    constants => [
        HO => 'GE',
        FU => {
            value => 'GA',
            comment => 'fuga',
        },
        PI => 3.14,
    ],
), "package Hoge::Piyo;
use strict;
use warnings;
use utf8;

use Const::Common (
    HO => 'GE',
    FU => 'GA', # fuga
    PI => 3.14,
);

1;
");

done_testing;
