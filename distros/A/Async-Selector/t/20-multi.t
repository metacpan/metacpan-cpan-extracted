use strict;
use warnings;
use Test::More;
use Test::Builder;

use FindBin;
use lib "$FindBin::RealBin/lib";
use Async::Selector::testutils;


package Async::Selector::Sample::Resources;
use strict;
use warnings;

sub new {
    my ($class, $selector, @names) = @_;
    my $self =  bless {
        selector => $selector,
        resources => { map {$_ => ""} @names },
    }, $class;
    my %register_params = ();
    foreach my $name (@names) {
        $register_params{$name} = sub {
            my ($min_length) = @_;
            return length($self->{resources}{$name}) >= $min_length ? $self->{resources}{$name} : undef;
        };
    }
    $selector->register(%register_params);
    return $self;
}

sub get {
    my ($self, @names) = @_;
    return @{$self->{resources}}{@names};
}

sub set {
    my ($self, %vals) = @_;
    @{$self->{resources}}{keys %vals} = values %vals;
    $self->{selector}->trigger(keys %vals);
}

package main;

BEGIN {
    use_ok('Async::Selector');
}

sub collector {
    my ($result_ref, $one_shot) = @_;
    return sub {
        my ($w, %res) = @_;
        ok(defined($res{$_}), "value for key $_ is defined.") foreach keys %res;
        push(@$result_ref, map { sprintf("%s:%s", $_, $res{$_}) } keys %res);
        if($one_shot) {
            $w->cancel();
        }
    };
}

sub checkResult {
    my ($result_ref, @exp_list) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    checkArray('result', $result_ref, @exp_list);
}

{
    note('--- N-resource: resources in watcher callback should only have keys for available resource.');
    my $s = new_ok('Async::Selector');
    my $rs = Async::Selector::Sample::Resources->new($s, 1 .. 5);
    my $fired = 0;
    my $w;
    $w = $s->watch(1 => 0, 2 => 5, 4 => 2, sub {
        my ($watcher, %res) = @_;
        $fired = 1;
        ok(!defined($w), '$w is not defined at this time because this is immediate fire.');
        checkCond($watcher, [1,2,4], {1=>0, 2=>5, 4=>2}, "watcher in callback");
        is($res{1}, "", "got resource 1");
        ok(!exists($res{$_}), "No key for resource $_") foreach 2..5;
        $watcher->cancel();
    });
    ok($fired, "watcher fired.");
    ok(!$w->active, "watcher fired.");
    
    $fired = 0;
    $w = $s->watch(3 => 3, 4 => 4, 5 => 5, 6 => 6, sub {
        my ($watcher, %res) = @_;
        $fired = 1;
        is($watcher, $w, '$watcher is actually $w.');
        checkCond($watcher, [3,4,5,6], {3=>3, 4=>4, 5=>5, 6=>6}, "watcher in callback");
        is($res{3}, "cccc", "got resource 3");
        is($res{4}, "dddd", "got resource 4");
        ok(!exists($res{$_}), "No key for resource $_") foreach (1,2,5,6);
    });
    ok(!$fired, "not yet fired");
    ok($w->active);
    $rs->set(1 => 'aaaa', 2 => 'bbbb', 3 => 'cccc', 4 => "dddd", 5 => "eeee");
    ok($fired, "fired");
    ok($w->active);
    $w->cancel();
    $fired = 0;
    ok(!$w->active);
    $rs->set(1 => 'aaaaaa', 2 => 'bbbbbb', 3 => 'cccccc', 4 => "dddddd", 5 => "eeeeee");
    ok(!$fired, "not fired because already canceled");
}

{
    note('--- N-resource, registered()');
    my $s = new_ok('Async::Selector');
    my $rs = Async::Selector::Sample::Resources->new($s, 1 .. 10);
    ok( $s->registered($_), "$_ is registered") foreach (1..10);
    ok(!$s->registered($_), "$_ is not registered") foreach (0, 11..15);
}

{
    note('--- N-resource, 1-watch.');
    my $N = 5;
    my $s = new_ok('Async::Selector');
    my $rs = Async::Selector::Sample::Resources->new($s, 1 .. $N);
    my @result = ();
    my $w = $s->watch(1 => 3, 2 => 4, 3 => 2, 4 => 9, 5 => 2, collector(\@result, 1));
    ok($w->active, "w is active now.");
    checkResult \@result;
    $rs->set(1 => "sk", 2 => "sas", 3 => "", 4 => "abcdefgh", 5 => "Y");
    checkResult \@result;
    $rs->set(1 => "ab", 2 => "asas", 3 => "BB",               5 => "ybb");
    checkResult \@result, qw(2:asas 3:BB 5:ybb);
    checkWatchers $s;
    ok(!$w->active, "w is fired and inactive now");
    @result = ();
    $rs->set(map {$_ => "this_is_a_long_string"} 1 .. $N);
    cmp_ok(int(@result), "==", 0, "no result because the watcher is removed.");

    @result = ();
    $w = $s->watch(1 => 0, 2 => 3, 3 => 4, collector(\@result, 0));
    checkResult \@result, qw(1:this_is_a_long_string 2:this_is_a_long_string 3:this_is_a_long_string);
    @result = ();
    $rs->set(1 => "", 2 => "aa", 3 => "bb", 4 => "cc", 5 => "dd");
    checkResult \@result, qw(1:);
    checkWatchers $s, $w;
    ok($w->active, "w is active");
    @result = ();
    $s->trigger(1 .. $N);
    checkResult \@result, qw(1:);
    @result = ();
    $s->trigger(3);
    checkResult \@result;
    @result = ();
    $rs->set(2 => "aaa", 3 => "bbbb", 4 => "ccccc", 5 => "dddddd");
    ok($w->active, "w is still active");
    checkResult \@result, qw(2:aaa 3:bbbb);

    note("--- -- if the triggered resource is not selected, the watcher callback is not executed.");
    @result = ();
    $s->trigger(4, 5);
    checkResult \@result;

    checkWatchers $s, $w;
    $w->cancel();
    checkWatchers $s;
    ok(!$w->active, "w is inactive now");

    @result = ();
    $rs->set(map {$_ => ""} 1 .. $N);
    checkResult \@result;

    @result = ();
    $w = $s->watch(3 => 3, 4 => 4, 5 => 5, collector(\@result, 0));
    checkResult \@result;
    checkWatchers $s, $w;
    @result = ();
    $rs->set(1 => "a", 2 => "b", 3 => "c", 4 => "d", 5 => "e");
    checkResult \@result;
    @result = ();
    $rs->set(1 => "a" x 3, 2 => "b" x 3, 3 => "c" x 3, 4 => "d" x 3, 5 => "e" x 3);
    checkResult \@result, qw(3:ccc);
    @result = ();
    $rs->set(1 => "a" x 4, 2 => "b" x 4, 3 => "c" x 4, 4 => "d" x 4, 5 => "e" x 4);
    checkResult \@result, qw(3:cccc 4:dddd);
    @result = ();
    $rs->set(1 => "a" x 5, 2 => "b" x 5, 3 => "c" x 5, 4 => "d" x 5, 5 => "e" x 5);
    checkResult \@result, qw(3:ccccc 4:ddddd 5:eeeee);
}

{
    note('--- 1-resource, M-watchers');
    my $s = new_ok('Async::Selector');
    my $rs = Async::Selector::Sample::Resources->new($s, 1);
    my @result = ();
    note('--- -- continuous watchers');
    my @watchers = ();
    my $w;
    push @watchers, $s->watch(1 => 1, collector(\@result, 0));
    push @watchers, $s->watch(1 => 2, collector(\@result, 0));
    checkResult \@result;
    checkWatchers $s, @watchers;
    $rs->set(1 => "A");
    checkResult \@result, qw(1:A);
    checkWatchers $s, @watchers;
    @result = ();
    $rs->set(1 => "BB");
    checkResult \@result, qw(1:BB 1:BB);
    checkWatchers $s, @watchers;
    @result = ();
    $rs->set(1 => 'a');
    checkResult \@result, qw(1:a);
    checkWatchers $s, @watchers;
    ok($_->active, "watcher active") foreach @watchers;
    $_->cancel() foreach @watchers;
    checkWatchers $s;
    @result = ();
    $rs->set(1 => 'abcde');
    checkResult \@result;
    ok(!$_->active, "watcher inactive") foreach @watchers;

    note('--- -- one-shot watchers');
    @result = ();
    $w = $s->watch(1 => 4, collector(\@result, 1));
    ok(!$w->active, "immediate fire gives inactive watcher");
    checkCond($w, [1], {1 => 4}, "inactive watcher");
    checkResult \@result, qw(1:abcde);
    checkWNum $s, 0;
    $w = $s->watch(1 => 6, collector(\@result, 1));
    ok($w->active, "this is still active");
    checkCond($w, [1], {1 => 6}, "active watcher");
    checkResult \@result, qw(1:abcde);
    checkWNum $s, 1;
    $w = $s->watch(1 => 7, collector(\@result, 1));
    ok($w->active, "this is still active");
    checkResult \@result, qw(1:abcde);
    checkWNum $s, 2;
    $w = $s->watch(1 => 3, collector(\@result, 1));
    ok(!$w->active, "fire immediately");
    checkResult \@result, qw(1:abcde 1:abcde);
    checkWNum $s, 2;
    $w = $s->watch(1 => 8, collector(\@result, 1));
    ok($w->active, "still active");
    checkResult \@result, qw(1:abcde 1:abcde);
    checkWNum $s, 3;
    $w = $s->watch(1 => 9, collector(\@result, 1));
    ok($w->active, "still active");
    checkResult \@result, qw(1:abcde 1:abcde);
    checkWNum $s, 4;
    @result = ();
    $rs->set(1 => "666666");
    checkResult \@result, "1:666666";
    checkWNum $s, 3;
    $rs->set(1 => "7777777");
    checkResult \@result, qw(1:666666 1:7777777);
    checkWNum $s, 2;
    $rs->set(1 => "88888888");
    checkResult \@result, qw(1:666666 1:7777777 1:88888888);
    checkWNum $s, 1;
    $rs->set(1 => "999999999");
    checkResult \@result, qw(1:666666 1:7777777 1:88888888 1:999999999);
    checkWNum $s, 0;
    @result = ();
    foreach my $num (10 .. 15) {
        $rs->set(1 => "A" x $num);
        checkResult \@result;
    }
    
    note('--- -- mix one-shot and continuous watchers');
    $rs->set(1 => "");
    @result = ();
    @watchers = ();
    push @watchers, $s->watch(1 => 5, collector(\@result, 0));
    push @watchers, $s->watch(1 => 6, collector(\@result, 1));
    push @watchers, $s->watch(1 => 7, collector(\@result, 0));
    push @watchers, $s->watch(1 => 8, collector(\@result, 1));
    checkResult \@result;
    checkWatchers $s, @watchers;
    @result = ();
    $rs->set(1 => "qqqq");
    checkResult \@result;
    checkWNum $s, 4;
    @result = ();
    $rs->set(1 => "wwwww");
    checkResult \@result, "1:wwwww";
    checkWNum $s, 4;
    @result = ();
    $rs->set(1 => "eeeeee");
    checkResult \@result, qw(1:eeeeee 1:eeeeee);
    checkWNum $s, 3;
    ok(!$watchers[1]->active, "watcher 1 fired and gets inactive.");
    @result = ();
    $rs->set(1 => "rrrrrrr");
    checkResult \@result, qw(1:rrrrrrr 1:rrrrrrr);
    checkWNum $s, 3;
    @result = ();
    $rs->set(1 => "tttttttt");
    checkResult \@result, qw(1:tttttttt 1:tttttttt 1:tttttttt);
    checkWNum $s, 2;
    ok(!$watchers[3]->active, "watcher 3 fired and gets inactive.");
    foreach my $num (9 .. 12) {
        @result = ();
        $rs->set(1 => ("A" x $num));
        checkResult \@result, ('1:' . ("A" x $num)) x 2;
    }
    $_->cancel() foreach @watchers;
    checkWNum $s, 0;
    foreach my $i (1 .. 3) {
        @result = ();
        $rs->set(1 => "PPPPPPPPPPPPPP");
        checkResult \@result;
    }
    
    note('--- -- cancel() some of the watchers');
    $rs->set(1 => "a");
    @watchers = ();
    @result = ();
    push @watchers, $s->watch(1 => $_, collector(\@result, 0)) foreach 1 .. 10;
    checkResult \@result, "1:a";
    checkWatchers $s, @watchers;
    @result = ();
    $_->cancel() foreach @watchers[2, 4, 5, 8]; ## 1 2 4 7 8 10
    checkWatchers $s, @watchers[0, 1, 3, 6, 7, 9];
    $rs->set(1 => "bbbbbb");
    checkResult(\@result, ("1:bbbbbb") x 3);
}

{
    note('--- N-resource, M-watchers');
    my $s = new_ok('Async::Selector');
    my $rs = Async::Selector::Sample::Resources->new($s, 1 .. 5);
    my @result = ();
    my @w = ();
    push @w, $s->watch(1 => 5, 2 => 5, 3 => 5                , collector(\@result, 1));
    push @w, $s->watch(        2 => 4, 3 => 4, 4 => 4        , collector(\@result, 1));
    push @w, $s->watch(1 => 5,                 4 => 5, 5 => 5, collector(\@result, 1));
    push @w, $s->watch(        2 => 0, 3 => 0, 4 => 3, 5 => 5, collector(\@result, 1));
    push @w, $s->watch(1 => 2,                 4 => 5, 5 => 2, collector(\@result, 1));
    push @w, $s->watch(        2 => 4, 3 => 4                , collector(\@result, 1));
    checkCond($w[0], [1,2,3], {1 => 5, 2 => 5, 3 => 5}, "watcher 0");
    checkCond($w[1], [2,3,4], {2 => 4, 3 => 4, 4 => 4}, "watcher 1");
    checkCond($w[2], [1,4,5], {1 => 5, 4 => 5, 5 => 5}, "watcher 2");
    checkCond($w[3], [2,3,4,5], {2 => 0, 3 => 0, 4 => 3, 5 => 5}, "watcher 3");
    checkCond($w[4], [1,4,5], {1 => 2, 4 => 5, 5 => 2}, "watcher 4");
    checkCond($w[5], [2,3], {2 => 4, 3 => 4}, "watcher 5");
    checkResult \@result, qw(2: 3:);
    checkWNum $s, 5;
    @result = ();
    $rs->set(1 => "aa", 5 => "aa");
    checkResult \@result, qw(1:aa 5:aa);
    checkWNum $s, 4;
    @result = ();
    $rs->set(3 => "AAAA", 4 => "AAAA");
    checkResult \@result, qw(3:AAAA 3:AAAA 4:AAAA);
    checkWNum $s, 2;
    @result = ();
    $rs->set(map {$_ => "bbbbbb"} 1 .. 5);
    checkResult \@result, qw(1:bbbbbb 2:bbbbbb 3:bbbbbb 1:bbbbbb 4:bbbbbb 5:bbbbbb);
    checkWNum $s, 0;
    @result = ();
    $rs->set(map {$_ => "cccccccccccc"} 1 .. 5);
    checkResult \@result;
    checkWNum $s, 0;
}

{
    note('--- 2 selectors with same resource names');
    my @s = ();
    my @r = ();
    my @w = ();
    my @results = ([], []);
    foreach my $i (0 .. 1) {
        $s[$i] = Async::Selector->new();
        $r[$i] = Async::Selector::Sample::Resources->new($s[$i], 1..5);
        $w[$i] = $s[$i]->watch(2 => 2, 3 => 3, 4 => 4, 6 => 6, sub {
            my ($w, %res) = @_;
            is($w, $w[$i], "correct watcher");
            push(@{$results[$i]}, map { "${i}_$_:$res{$_}" } sort {$a cmp $b} keys %res);
            $w->cancel();
        });
    }
    ok($_->active, "both active") foreach @w;
    is_deeply(\@results, [[], []], "no results");
    $r[0]->set(1 => "aaaaa");
    $r[1]->set(5 => "eeeee");
    ok($_->active, "both active") foreach @w;
    is_deeply(\@results, [[], []], "still no results");
    $r[0]->set(3 => "cccc", 4 => "dddd");
    $r[1]->set(2 => "b", 4 => "ddd");
    ok(!$w[0]->active, "w0 fired");
    ok($w[1]->active, "w1 still active");
    is_deeply(\@results, [['0_3:cccc', '0_4:dddd'], []]);
    $r[0]->set(2 => "bbbbbbb");
    $r[1]->set(2 => "bbbbbbb");
    ok(!$w[1]->active, "w1 fired");
    is_deeply(\@results, [['0_3:cccc', '0_4:dddd'], ['1_2:bbbbbbb']]);
}

done_testing();

