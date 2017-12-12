use strict;
use warnings;

use Test::More tests => 1;
BEGIN { 
    SKIP: {
        eval "use Lexical::Persistence 1.01 ()";
        skip "Lexical::Persistence not installed", 1 if $@;
        use_ok('App::PerlShell::LexPersist')
    }
};
