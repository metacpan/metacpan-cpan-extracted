use Test::More "no_plan";
{
no warnings;
no strict;    # things are likely to be sloppy

ok 1 => 'the tests compile';   

use Test::Output;
    use feature 'say';


#line 65 lib/Async/Trampoline.pm
use Async::Trampoline qw(
    await
    async async_value async_error async_cancel
    async_yield
);

;

#line 71 lib/Async/Trampoline.pm
# creating asyncs
$async = async_value 1, 2, 3;
$async = async_error "oops";
$async = async_cancel;
$async = async { ...; return $new_async };

;
$async = async_value 1, 2, 3;


#line 80 lib/Async/Trampoline.pm
# running asyncs
@result = $async->run_until_completion;

;
is "@result", "1 2 3";

$other_async = async { async_value "other async" };
    $new_async = async_value "new async";
    $x = async_value "x";
    $y = async_value "y";


#line 92 lib/Async/Trampoline.pm
# combining asyncs
$async = $other_async->await(sub {
    my (@values) = @_;
    # ...
    return $new_async;
});
$async = await [$x, $y] => sub {
    my (@x_and_y_values) = @_;
    # ...
    return $new_async;
};
$async = $x->complete_then($y);
$async = $x->resolved_or($y);
$async = $x->resolved_then($y);
$async = $x->value_or($y);
$async = $x->value_then($y);
$async = $x->concat($y);

;

#line 110 lib/Async/Trampoline.pm
# generators
$gen = async_yield async_value(1, 2, 3) => sub {
    # ...
    return $next_generator;
};
$gen = $gen->gen_map(sub {
    my (@values) = @_;
    # ...
    return $new_async;
});
$async = $gen->gen_foreach(sub {
    my (@values) = @_;
    return async_cancel if not @values;  # like "last" in Perl
    # ...
    return async_value;  # like "next" in Perl
});
$async = $gen->gen_collect;

;

#line 128 lib/Async/Trampoline.pm
# misc
$str = $async->to_string;
$bool = $async->is_complete;
$bool = $async->is_cancelled;
$bool = $async->is_error;
$bool = $async->is_value;

;

#line 160 lib/Async/Trampoline.pm
my @items;

;

#line 162 lib/Async/Trampoline.pm
my $i = 5;
while ($i) {
    push @items, $i--;
}

;
is "@items", "5 4 3 2 1", q(Synchronous/imperative);


#line 172 lib/Async/Trampoline.pm
sub loop {
    my ($items, $i) = @_;
    return $items if not $i;
    push @$items, $i--;
    return loop($items, $i);  # may lead to deep recursion!
}

;

#line 179 lib/Async/Trampoline.pm
my $items = loop([], 5);

;
is "@$items", "5 4 3 2 1", q(Synchronous/recursive);


#line 186 lib/Async/Trampoline.pm
sub loop_async {
    my ($items, $i) = @_;
    return async_value $items if not $i;
    push @$items, $i--;
    return async { loop_async($items, $i) };
}

;

#line 193 lib/Async/Trampoline.pm
my $items = loop_async([], 5)->run_until_completion;

;
is "@$items", "5 4 3 2 1", q(Async/recursive);


#line 200 lib/Async/Trampoline.pm
sub loop_gen {
    my ($i) = @_;
    return async_cancel if not $i;
    return async_yield async_value($i) => sub {
        return loop_gen($i - 1);
    };
}

;

#line 208 lib/Async/Trampoline.pm
my $items = loop_gen(5)->gen_collect->run_until_completion;

;
is "@$items", "5 4 3 2 1", q(Async/generators);

 
#line 265 lib/Async/Trampoline.pm
$async = async { ... };

;

#line 274 lib/Async/Trampoline.pm
$async = async_value @values;

;

#line 281 lib/Async/Trampoline.pm
$async = async_error $error;

;

#line 290 lib/Async/Trampoline.pm
$async = async_cancel;

;
$dependency = async { async_value 1,2, 3 };
    @dependencies = (async_value(1), async_value(), async_value(3));


#line 303 lib/Async/Trampoline.pm
$async = $dependency->await(sub {
    my (@result) = @_;
    # ...
    return $new_async;
});

;

#line 309 lib/Async/Trampoline.pm
$async = await $dependency => sub {
    my (@result) = @_;
    # ...
    return $new_async;
};

;

#line 315 lib/Async/Trampoline.pm
$async = await [@dependencies] => sub {
    my (@results) = @_;
    # ...
    return $new_async;
};

;
$first_async = async { async_value };
    $alternative_async = async { async_value };
    $second_async = $alternative_async;


#line 338 lib/Async/Trampoline.pm
$async = $first_async->resolved_or($alternative_async);
$async = $first_async->value_or($alternative_async);

;

#line 359 lib/Async/Trampoline.pm
$async = $first_async->complete_then($second_async);
$async = $first_async->resolved_then($second_async);
$async = $first_async->value_then($second_async);

;

#line 386 lib/Async/Trampoline.pm
$async = $first_async->concat($second_async);

;

#line 392 lib/Async/Trampoline.pm
$async = (async_value 1, 2, 3)->concat(async_value 4, 5);
#=> async_value 1, 2, 3, 4, 5

;
{ my @result = $async->run_until_completion;
    is "@result", "1 2 3 4 5", q(concat());
}


#line 419 lib/Async/Trampoline.pm
sub count_down_generator {
    my ($i) = @_;
    return async_cancel if $i < 0;
    return async_yield async_value($i) => sub {
        return count_down_generator($i - 1);
    };
}

;

#line 427 lib/Async/Trampoline.pm
my $countdown_gen = count_down_generator(10);

;

#line 431 lib/Async/Trampoline.pm
$countdown_gen = $countdown_gen->gen_map(sub {
    my ($i) = @_;
    return async_value "ignition" if $i == 3;
    return async_value "liftoff"  if $i == 0;
    return async_value $i;
});

;
$result = $countdown_gen->gen_collect->run_until_completion;
    is "@$result", "10 9 8 7 6 5 4 ignition 2 1 liftoff", q(countdown map);


#line 444 lib/Async/Trampoline.pm
my $finished_async = $countdown_gen->gen_foreach(sub {
    my ($i) = @_;
    say $i;
    return async_value;  # request next item
});

;
stdout_is { $result = $finished_async->run_until_completion }
        (join q() => map "$_\n" => qw( 10 9 8 7 6 5 4 ignition 2 1 liftoff )),
        q(countdown stdout);
    is $result, undef, q(countdown result);


#line 458 lib/Async/Trampoline.pm
sub repeat_gen {
    my ($gen) = @_;
    return $gen->await(sub {
        my ($continuation, $x) = @_;
        return async_yield async_value($x) => sub {
            return async_yield async_value($x) => sub {
                repeat_gen($continuation);
            };
        };
    });
}

;
$result = repeat_gen(count_down_generator(2))
        ->gen_collect
        ->run_until_completion;
    is "@$result", "2 2 1 1 0 0", q(repetition);


#line 478 lib/Async/Trampoline.pm
$generator = async_yield $async => sub { return $next_generator }

;

#line 488 lib/Async/Trampoline.pm
$generator = $generator->gen_map(sub {
    my (@values) = @_;
    # ...
    return $new_async;
});

;

#line 506 lib/Async/Trampoline.pm
$async = $generator->gen_foreach(sub {
    my (@values) = @_;
    # ...
    return async_value;
});

;

#line 523 lib/Async/Trampoline.pm
$async = $generator->gen_collect;

;
$async = async { async_value 1, 2, 3 };


#line 535 lib/Async/Trampoline.pm
@result = $async->run_until_completion;

;
is "@result", "1 2 3", q(run_until_completion());


#line 553 lib/Async/Trampoline.pm
$str = $async->to_string;
$str = "$async";

;

#line 568 lib/Async/Trampoline.pm
$bool = $async->is_complete;
$bool = $async->is_cancelled;
$bool = $async->is_resolved;
$bool = $async->is_error;
$bool = $async->is_value;

;


ok 1 => 'we reached the end!';

}
