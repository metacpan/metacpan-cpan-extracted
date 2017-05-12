use Contextual::Return;
use Test::More 'no_plan';
use Carp qw< croak cluck  confess >;

sub foo {
    return
        BOOL      { cluck 'oops! Bool'; 1              }
        NUM       { cluck 'oops! Num'; return 7;       }
        ARRAYREF  { cluck 'oops! Array'; return [1,2]; }
        HASHREF   { {name=>'foo', value=>42 }         }
        VOID      { confess 'Enter not the Abyss!';     }
    ;
}

sub ok_if_warn {
    my ($msg, $line) = @_;
    return sub {
#        diag( "Caught warning: '@_'" );
        ok $_[0] =~ $msg              => "Warn msg correct at line $line";
        ok $_[0] =~ /line $line\.?\Z/ => "Line number correct at line $line"
            if $line;
    }
}

local $SIG{__WARN__} = ok_if_warn 'oops! Bool', __LINE__+1;
if (my $foo = foo()) {
    local $SIG{__WARN__} = ok_if_warn 'oops! Bool', __LINE__+1;
    ok +($foo?1:0)              => 'BOOLEAN';

    local $SIG{__WARN__} = ok_if_warn 'oops! Num', __LINE__+1;
    ok "$foo"                   => 'STRING';

    local $SIG{__WARN__} = ok_if_warn 'oops! Array', __LINE__+1;
    ok  $foo->[0]               => 'ARRAYREF';

    local $SIG{__WARN__} = sub { ok 0 => "Unexpected warning: @_" };
    is $foo->{name}, 'foo'      => 'HASHREF (name)';

    is $foo->{value}, 42        => 'HASHREF (value)';
}

local $SIG{__WARN__} = ok_if_warn 'oops! Array', __LINE__+1;
my @bar = foo();
ok @bar                         => 'LIST via ARRAYREF';

my $line = __LINE__+1;
ok !eval { foo(); 1 }           => 'VOID is fatal';
like $@, qr/Abyss/              => 'Error message is correct';
like $@, qr/line $line\Z/       => 'Error line is correct';


sub double_or_nothing {
    return LIST { 1..9 }
            NUM { 10 }
           LIST { 11..100 };
}

eval { double_or_nothing(); };
my $exception = $@;
ok $exception   => 'Exception on repetition';
like $exception, qr/Can't install two LIST handlers/ => 'Correct exception';

eval "use Contextual::Return 'HANDLER'; ";
use Data::Dumper 'Dumper';
$exception = $@;
ok $exception   => 'Exception on bad export name';
like $exception, qr/^Can't export HANDLER: no such handler/
                => 'Correct exception';

eval "use Contextual::Return {HANDLER=>'FOO'}; ";
use Data::Dumper 'Dumper';
$exception = $@;
ok $exception   => 'Exception on bad export type';
like $exception, qr/^Can't use HASH as export specifier/
                => 'Correct exception';

local $SIG{__WARN__} = ok_if_warn q{didn't export anything};
eval 'use Contextual::Return qr/HANDLER/';
