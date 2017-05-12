use Contextual::Return;
use Test::More tests => 8;

no warnings 'uninitialized';

sub foo {
    return
        BOOL      { die 'oops! Bool'; 1              }
        NUM       { die 'oops! Num'; return 7;       }
        STR       { die 'oops! Num'; return 7;       }
        VOID      { die 'Enter not the Abyss!';      }
        RECOVER   { ok 1 => "Recovered";             } 
    ;
}

my $foo = foo();

ok +($foo?0:1)                  => 'BOOLEAN';
ok not("$foo")                  => 'STRING';
ok not(0+$foo)                  => 'NUM';
ok do{;foo;1}                   => 'VOID';
