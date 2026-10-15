#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($val);

# What goes in comes back out, and is the variable's own copy.

my $scope = \&Context::Vars::_t_scope;

$scope->(sub {
    my @cases = (
        [ string      => 'plain' ],
        [ number      => 42 ],
        [ float       => 3.25 ],
        [ negative    => -7 ],
        [ big         => 2**52 ],
        [ zero_string => '0.0' ],
        [ nul_byte    => "a\0b" ],
        [ utf8        => "caf\x{e9} \x{263a}" ],
        [ latin1      => "caf\xe9" ],
        [ newline     => "two\nlines" ],
        [ long        => 'x' x 100_000 ],
    );
    for my $c (@cases) {
        my ($what, $in) = @$c;
        $val = $in;
        is($val, $in, "$what comes back as it went in");
    }
    $val = "\x{263a}";
    ok(utf8::is_utf8($val), 'a character string keeps its flag');
    is(length $val, 1, 'and is one character long');

    my $aref = [1, 2];
    $val = $aref;
    is_deeply($val, [1, 2], 'an array reference comes back with its contents');
    push @$aref, 3;
    is_deeply($val, [1, 2], 'and is the variable\'s own copy: changing the original does not change it');

    my $obj = bless { n => 1 }, 'V::Obj';
    $val = $obj;
    isa_ok($val, 'V::Obj', 'a blessed object');
    is($val->{n}, 1, 'with its contents');

    my $code = sub { 'called ' . shift };
    $val = $code;
    is($val->('it'), 'called it', 'a code reference can be called');

    # The stored value is the variable's own: the source scalar is not kept.
    my $src = 'source';
    $val = $src;
    $src = 'changed';
    is($val, 'source', 'changing the scalar that was assigned does not change the variable');

    # Reading into a lexical takes a copy, which may be changed freely.
    $val = 'kept';
    my $mine = $val;
    $mine .= ' and changed';
    is($val, 'kept', 'changing a copy that was read does not change the variable');

    # Stored values are read-only inside the context; the variable is not.
    $val = 'ro';
    my ($stored) = Context::Vars::_t_fetch('val');
    $val = 'writable again';
    is($val, 'writable again', 'the variable can always be assigned again');
});

# ---- an object lives exactly as long as a context holds it ------------------------
{
    my $destroyed = 0;
    { package V::Probe; sub DESTROY { $destroyed++ } }
    my $kept;
    $scope->(sub {
        $val = bless {}, 'V::Probe';
        is($destroyed, 0, 'an object assigned to a variable is alive while its context is');
        $val = bless {}, 'V::Probe';
        is($destroyed, 1, 'assigning another value lets the first one go');
        $kept = Context::Vars::_t_capture();
    });
    is($destroyed, 1, 'a capture keeps the second alive after the scope');
    Context::Vars::_t_release($kept);
    is($destroyed, 2, 'and it goes, once, when the capture is let go');

    $scope->(sub { $val = bless {}, 'V::Probe'; $val = undef; });
    is($destroyed, 3, 'assigning undef lets a value go at once');
    $scope->(sub { $val = bless {}, 'V::Probe' });
    is($destroyed, 4, 'and leaving the scope lets it go');
}

# ---- the variable itself never keeps an object alive ------------------------------
{
    my $destroyed = 0;
    { package V::Probe2; sub DESTROY { $destroyed++ } }
    my $kept;
    $scope->(sub {
        $val = bless {}, 'V::Probe2';
        my $copy = $val;
        isa_ok($val, 'V::Probe2', 'read after assignment');
        ok(ref $val, 'and read again');
        $kept = $copy;
    });
    is($destroyed, 0, 'a copy read from the variable is a strong reference of its own');
    undef $kept;
    is($destroyed, 1, 'and the object goes when that copy goes, though the variable was read last');
    $scope->(sub {
        $val = bless {}, 'V::Probe2';
        my $n = 0;
        $n++ for grep { ref } ($val, $val, $val);
        is($n, 3, 'read three times in one list');
    });
    is($destroyed, 2, 'and still let go with the scope');
}

is(Context::Vars::_depth(), 0, 'nothing is left entered');
is(Context::Vars::_live_holders(), 0, 'and no holder is out');

done_testing;
