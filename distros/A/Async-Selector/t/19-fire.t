use strict;
use warnings;
use Test::More;
use Test::Builder;
use Async::Selector;


{
    note('--- N-resource, 1-watcher: condition to fire (trigger)');
    my $s = Async::Selector->new();

    ## Resource description:
    ##   w: watched,   W: not watched
    ##   a: available(1), b: available(2), A: not available, E: not existing
    $s->register(
        wa => sub { 1 },
        wb => sub { 1 },
        wA => sub { undef },
        Wa => sub { 1 },
        WA => sub { undef }
    );
    my $fired = 0;
    my %result = ();
    $s->watch_et(wa => 1, wb => 1, wA => 1, wE => 1, sub {
        my ($watcher, %res) = @_;
        $fired = 1;
        %result = %res;
    });
    my $check = sub {
        my ($triggers, $exp_fired, $exp_result) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $fired = 0;
        %result = ();
        $s->trigger(@$triggers);
        is($fired, $exp_fired, "fired OK");
        is_deeply(\%result, $exp_result, "result OK");
    };
    
    ## ## ** test case generator. C-u C-| perl -e 'PASTE HERE'
    ## @a=qw(wa wb wA Wa WA wE WE);
    ## sub f {
    ##     my $index = shift;
    ##     return "" if $index > $#a;
    ##     my @seq = f($index+1);
    ##     return ((map { "   " . $_  } @seq), (map { "$a[$index] " . $_ } @seq));
    ## };
    ## print map { "\$check->([qw($_)]);\n" } f(0);
    
    $check->([qw(                     )], 0, {});
    $check->([qw(                  WE )], 0, {});
    $check->([qw(               wE    )], 0, {});
    $check->([qw(               wE WE )], 0, {});
    $check->([qw(            WA       )], 0, {});
    $check->([qw(            WA    WE )], 0, {});
    $check->([qw(            WA wE    )], 0, {});
    $check->([qw(            WA wE WE )], 0, {});
    $check->([qw(         Wa          )], 0, {});
    $check->([qw(         Wa       WE )], 0, {});
    $check->([qw(         Wa    wE    )], 0, {});
    $check->([qw(         Wa    wE WE )], 0, {});
    $check->([qw(         Wa WA       )], 0, {});
    $check->([qw(         Wa WA    WE )], 0, {});
    $check->([qw(         Wa WA wE    )], 0, {});
    $check->([qw(         Wa WA wE WE )], 0, {});
    $check->([qw(      wA             )], 0, {});
    $check->([qw(      wA          WE )], 0, {});
    $check->([qw(      wA       wE    )], 0, {});
    $check->([qw(      wA       wE WE )], 0, {});
    $check->([qw(      wA    WA       )], 0, {});
    $check->([qw(      wA    WA    WE )], 0, {});
    $check->([qw(      wA    WA wE    )], 0, {});
    $check->([qw(      wA    WA wE WE )], 0, {});
    $check->([qw(      wA Wa          )], 0, {});
    $check->([qw(      wA Wa       WE )], 0, {});
    $check->([qw(      wA Wa    wE    )], 0, {});
    $check->([qw(      wA Wa    wE WE )], 0, {});
    $check->([qw(      wA Wa WA       )], 0, {});
    $check->([qw(      wA Wa WA    WE )], 0, {});
    $check->([qw(      wA Wa WA wE    )], 0, {});
    $check->([qw(      wA Wa WA wE WE )], 0, {});
    $check->([qw(   wb                )], 1, {wb => 1});
    $check->([qw(   wb             WE )], 1, {wb => 1});
    $check->([qw(   wb          wE    )], 1, {wb => 1});
    $check->([qw(   wb          wE WE )], 1, {wb => 1});
    $check->([qw(   wb       WA       )], 1, {wb => 1});
    $check->([qw(   wb       WA    WE )], 1, {wb => 1});
    $check->([qw(   wb       WA wE    )], 1, {wb => 1});
    $check->([qw(   wb       WA wE WE )], 1, {wb => 1});
    $check->([qw(   wb    Wa          )], 1, {wb => 1});
    $check->([qw(   wb    Wa       WE )], 1, {wb => 1});
    $check->([qw(   wb    Wa    wE    )], 1, {wb => 1});
    $check->([qw(   wb    Wa    wE WE )], 1, {wb => 1});
    $check->([qw(   wb    Wa WA       )], 1, {wb => 1});
    $check->([qw(   wb    Wa WA    WE )], 1, {wb => 1});
    $check->([qw(   wb    Wa WA wE    )], 1, {wb => 1});
    $check->([qw(   wb    Wa WA wE WE )], 1, {wb => 1});
    $check->([qw(   wb wA             )], 1, {wb => 1});
    $check->([qw(   wb wA          WE )], 1, {wb => 1});
    $check->([qw(   wb wA       wE    )], 1, {wb => 1});
    $check->([qw(   wb wA       wE WE )], 1, {wb => 1});
    $check->([qw(   wb wA    WA       )], 1, {wb => 1});
    $check->([qw(   wb wA    WA    WE )], 1, {wb => 1});
    $check->([qw(   wb wA    WA wE    )], 1, {wb => 1});
    $check->([qw(   wb wA    WA wE WE )], 1, {wb => 1});
    $check->([qw(   wb wA Wa          )], 1, {wb => 1});
    $check->([qw(   wb wA Wa       WE )], 1, {wb => 1});
    $check->([qw(   wb wA Wa    wE    )], 1, {wb => 1});
    $check->([qw(   wb wA Wa    wE WE )], 1, {wb => 1});
    $check->([qw(   wb wA Wa WA       )], 1, {wb => 1});
    $check->([qw(   wb wA Wa WA    WE )], 1, {wb => 1});
    $check->([qw(   wb wA Wa WA wE    )], 1, {wb => 1});
    $check->([qw(   wb wA Wa WA wE WE )], 1, {wb => 1});
    $check->([qw(wa                   )], 1, {wa => 1});
    $check->([qw(wa                WE )], 1, {wa => 1});
    $check->([qw(wa             wE    )], 1, {wa => 1});
    $check->([qw(wa             wE WE )], 1, {wa => 1});
    $check->([qw(wa          WA       )], 1, {wa => 1});
    $check->([qw(wa          WA    WE )], 1, {wa => 1});
    $check->([qw(wa          WA wE    )], 1, {wa => 1});
    $check->([qw(wa          WA wE WE )], 1, {wa => 1});
    $check->([qw(wa       Wa          )], 1, {wa => 1});
    $check->([qw(wa       Wa       WE )], 1, {wa => 1});
    $check->([qw(wa       Wa    wE    )], 1, {wa => 1});
    $check->([qw(wa       Wa    wE WE )], 1, {wa => 1});
    $check->([qw(wa       Wa WA       )], 1, {wa => 1});
    $check->([qw(wa       Wa WA    WE )], 1, {wa => 1});
    $check->([qw(wa       Wa WA wE    )], 1, {wa => 1});
    $check->([qw(wa       Wa WA wE WE )], 1, {wa => 1});
    $check->([qw(wa    wA             )], 1, {wa => 1});
    $check->([qw(wa    wA          WE )], 1, {wa => 1});
    $check->([qw(wa    wA       wE    )], 1, {wa => 1});
    $check->([qw(wa    wA       wE WE )], 1, {wa => 1});
    $check->([qw(wa    wA    WA       )], 1, {wa => 1});
    $check->([qw(wa    wA    WA    WE )], 1, {wa => 1});
    $check->([qw(wa    wA    WA wE    )], 1, {wa => 1});
    $check->([qw(wa    wA    WA wE WE )], 1, {wa => 1});
    $check->([qw(wa    wA Wa          )], 1, {wa => 1});
    $check->([qw(wa    wA Wa       WE )], 1, {wa => 1});
    $check->([qw(wa    wA Wa    wE    )], 1, {wa => 1});
    $check->([qw(wa    wA Wa    wE WE )], 1, {wa => 1});
    $check->([qw(wa    wA Wa WA       )], 1, {wa => 1});
    $check->([qw(wa    wA Wa WA    WE )], 1, {wa => 1});
    $check->([qw(wa    wA Wa WA wE    )], 1, {wa => 1});
    $check->([qw(wa    wA Wa WA wE WE )], 1, {wa => 1});
    $check->([qw(wa wb                )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb             WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb          wE    )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb          wE WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb       WA       )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb       WA    WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb       WA wE    )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb       WA wE WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb    Wa          )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb    Wa       WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb    Wa    wE    )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb    Wa    wE WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb    Wa WA       )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb    Wa WA    WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb    Wa WA wE    )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb    Wa WA wE WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA             )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA          WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA       wE    )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA       wE WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA    WA       )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA    WA    WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA    WA wE    )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA    WA wE WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA Wa          )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA Wa       WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA Wa    wE    )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA Wa    wE WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA Wa WA       )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA Wa WA    WE )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA Wa WA wE    )], 1, {wa => 1, wb => 1});
    $check->([qw(wa wb wA Wa WA wE WE )], 1, {wa => 1, wb => 1});

    note('--- N-resource, 1-watcher: condition to fire (LT immediate)');
    my $check_lt = sub {
        my ($watched_resources, $exp_fired, $exp_result) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $fired = 0;
        %result = ();
        my $w = $s->watch((map { $_ => 1 } @$watched_resources), sub {
            my ($w, %res) = @_;
            $fired = 1;
            %result = %res;
        });
        $w->cancel();
        is($fired, $exp_fired, "fired OK");
        is_deeply(\%result, $exp_result, "result OK");
    };
    $check_lt->([qw(            )], 0, {});
    $check_lt->([qw(         wE )], 0, {});
    $check_lt->([qw(      wA    )], 0, {});
    $check_lt->([qw(      wA wE )], 0, {});
    $check_lt->([qw(   wb       )], 1, {wb => 1});
    $check_lt->([qw(   wb    wE )], 1, {wb => 1});
    $check_lt->([qw(   wb wA    )], 1, {wb => 1});
    $check_lt->([qw(   wb wA wE )], 1, {wb => 1});
    $check_lt->([qw(wa          )], 1, {wa => 1});
    $check_lt->([qw(wa       wE )], 1, {wa => 1});
    $check_lt->([qw(wa    wA    )], 1, {wa => 1});
    $check_lt->([qw(wa    wA wE )], 1, {wa => 1});
    $check_lt->([qw(wa wb       )], 1, {wa => 1, wb => 1});
    $check_lt->([qw(wa wb    wE )], 1, {wa => 1, wb => 1});
    $check_lt->([qw(wa wb wA    )], 1, {wa => 1, wb => 1});
    $check_lt->([qw(wa wb wA wE )], 1, {wa => 1, wb => 1});
}


done_testing();
