use Contextual::Return;

*foo = sub {
    return
        LIST      { [caller()], [caller(1)] }
        SCALAR    { (caller()||q{}) . '|' . (caller(1)||q{}) }
    ;
};

*bar = sub {
    return [CORE::caller()], [CORE::caller(1)] if wantarray;
    return (CORE::caller()||q{}) . '|' . (CORE::caller(1)||q{});
};

# This has to be on one line so the caller lines are the same...
*foo_2 = sub { return &foo; }; *bar_2 = sub { return &bar; };

package Other;
use Test::More 'no_plan';

# This has to be on one line so the caller lines are the same...
my @caller_foo = ::foo(); *::foo = *::bar; my @caller_bar = ::foo();

is_deeply [ \@caller_foo ], [ \@caller_bar ]  => 'Caller same both ways';

# This has to be on one line so the caller lines are the same...
my @caller_foo_2 = ::foo_2(); *::foo_2 = *::bar_2; my @caller_bar_2 = ::foo_2();

is_deeply [ \@caller_foo_2 ], [ \@caller_bar_2 ]  => 'Caller 2 same both ways';

my $caller_foo = ::foo(); *::foo = *::bar; my $caller_bar = ::foo();
is $caller_foo, $caller_bar  => 'Scalar caller same both ways';

my $caller_foo_2 = ::foo_2(); *::foo = *::bar; my $caller_bar_2 = ::foo_2();
is $caller_foo_2, $caller_bar_2  => 'Scalar caller 2 same both ways';
