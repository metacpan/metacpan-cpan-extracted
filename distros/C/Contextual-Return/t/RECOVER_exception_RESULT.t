use Contextual::Return;
use Test::More tests => 6;

no warnings 'uninitialized';

sub foo {
    return
        BOOL      { die 'oops! Bool'; 1                }
        NUM       { die 'oops! Num'; return 7;         }
        STR       { die 'oops! Num'; return 7;         }
        VOID      { die 'Enter not the Abyss!';        }
        RECOVER   { ok 1 => "Recovered"; RESULT { 42 } }
    ;
}

my $foo = foo();

ok +($foo?1:0)                  => 'BOOLEAN';
is "$foo", "42"                 => 'STRING';
ok $foo == 42                   => 'NUM';
