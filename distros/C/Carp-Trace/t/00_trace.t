use lib 'lib';
use Test::More 'no_plan';
BEGIN { $^W = 0 }
use_ok('Carp::Trace');

sub foo { bar() };
sub bar { $x = baz() };
sub baz { @y = zot() };
sub zot { $z = trace() };

### trace without args
{   eval 'foo(1)';

    ok( $z,                         "Trace obtained" );

    my @expect = (
        'main::(eval) [5]',
        'foo(1)',
        "$0 line",
        'main::foo [4]',
        'void - new stash',
        '(eval',
        'main::bar [3]',
        'void - new stash',
        "$0 line",
        'main::baz [2]',
        'scalar - new stash',
        "$0 line",
        'main::zot [1]',
        'list - new stash',
        "$0 line",
    );

    for my $line (@expect) {
        my $token = quotemeta $line;

        like( $z, qr/$token/,       "   Trace contains '$line'" );
    }

    undef $z;
}

{   local $Carp::Trace::ARGUMENTS = 1;
    eval foo('bar',[1]);

    ok( $z,                         "Trace with args" );

    my @expect = (
        'main::foo [4]',
        'scalar - new stash',
        "$0 line",
        "\$ARGS1 = 'bar'",
        '$ARGS2 = [',
        '1',
        '];',
        'main::bar [3]',
        'scalar - new stash',
        "$0 line",
        "\$ARGS1 = 'bar'",
        '$ARGS2 = [',
        '1',
        '];',
        'main::baz [2]',
        'scalar - new stash',
        "$0 line",
        'main::zot [1]',
        'list - new stash',
        "$0 line",
    );

    for my $line (@expect) {
        my $token = quotemeta $line;

        like( $z, qr/$token/,       "   Trace contains '$line'" );
    }

    undef $z;
}
