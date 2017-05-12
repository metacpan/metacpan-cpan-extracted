use strict;
use warnings;
use utf8;
use Test::More;
use B::Tap ':all';
use B;
use B::Tools;

plan skip_all => "Current implementation can't pass these tests.";

{
    package A;
    sub new { bless({}, shift) }
    sub bar { 'tanaka' }
}

{
    # Given the object
    my $foo = A->new;

    # And there is the coderef, calls method.
    my $code = sub {
        defined($foo->bar('ja'))
    };

    if (1) { concise_code($code) }

    # And find 'padsv' from the code's op tree
    my $cv = B::svref_2object($code);
    my @padsv = op_grep { $_->name eq 'padsv' } $cv->ROOT;
    is 0+@padsv, 1;

    # And tap the padsv OP.
    my @buf;
    for my $op (@padsv) {
        tap($op, $cv->ROOT, \@buf);
    }

    # When deparse the code.
    require B::Deparse;
    my $deparse = B::Deparse->new;
    my $txt = eval {
        $deparse->coderef2text($code);
    };
    my $e = $@;
    ok(!$e, 'There is no error was occurred') or diag $e;
    like $txt, qr{\$mech}, 'parsed correctly';

    # The output is nothing.
    is_deeply(
        \@buf,
        [
        ]
    );

    if (1) { concise_code($code) }
}

done_testing;

sub concise_code {
    my $code = shift;
    require B::Concise;
    my $walker = B::Concise::compile('-terse', '', $code);
    B::Concise::walk_output(\my $buf);
    $walker->();
    ::diag($buf);
}
