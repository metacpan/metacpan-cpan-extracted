use Test::More 'no_plan';
use Contextual::Return;

{
    sub foo : lvalue {
        my $x = 0;
        my $wantarray = wantarray;
        RVALUE { 
            BOOL { $x > 0 }
            STR  { "[$x]" }
            NUM  {   $x   }
        }
        LVALUE {
            $x = $_[0] * $_;
            is $CALLER::_, 'wunderbar' => 'Caller::_';
        }
        NVALUE {
            ok !defined $wantarray     => 'NVALUE context';
        }
    }
}

$_ = 'wunderbar';

for my $foo (foo 10) {
    is $foo+0,   0      => "Pre-numerication";
    is "$foo", "[0]"    => "Pre-stringification";
    ok !$foo            => "Pre-boolification";
    $foo = 99;
    is $foo+0,   990    => "Post-numerication";
    is "$foo", "[990]"  => "Post-stringification";
    ok $foo             => "Post-boolification";
}

is 0+foo,    0    => "Ex-numerication";
is "".foo, "[0]"  => "Ex-stringification";
ok !foo()         => "Ex-boolification";
foo(1) = 99;
is 0+foo,    0    => "Ex-post-numerication";
is "".foo, "[0]"  => "Ex-post-stringification";
ok !$foo          => "Ex-post-boolification";

foo();

my $f = \foo();


{
    sub foo2 : lvalue {
        LVALUE {
            ok 1;
        }
    }
}

for my $foo (foo2) {
    $foo = 99;
}
