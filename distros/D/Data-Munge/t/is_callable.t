#!perl
use Test2::V0;
use Data::Munge;

{
    package OverloadedFuncall;
    use overload (
        '&{}'    => sub { $_[0]->to_coderef },
        fallback => 1,
    );

    sub new {
        my $class = shift;
        bless {@_}, $class
    }

    sub to_coderef {
        my $self = shift;
        sub { $self->{value} }
    }
}

ok !is_callable(undef), "undef is not callable";
ok !is_callable(42), "a number is not callable";
ok !is_callable(\$_), "a scalar ref is not callable";
ok !is_callable([]), "an arrayref is not callable";
ok !is_callable({}), "a hashref is not callable";
ok !is_callable(*is_callable), "a glob is not callable";
ok !is_callable(\*is_callable), "a globref is not callable";
ok !is_callable(qr/./), "a regex is not callable";
ok !is_callable("a random string"), "a random string is not callable";
ok !is_callable("main::is_callable"), "a sub name is not callable";
ok is_callable(sub { die; }), "an anon sub ref is callable";
ok is_callable(\&is_callable), "a named sub ref is callable";
ok is_callable(\&no_such_sub), "an undefined sub is deemed callable";
ok is_callable(bless sub {}, 'SomeRandomClass'), "a blessed sub is callable";
{
    my $obj = OverloadedFuncall->new(value => 42);
    is $obj->(), 42, "sanity check: overloaded function call returns 42";
    ok is_callable($obj), "an object with overloaded &{} is callable";
}

done_testing;
