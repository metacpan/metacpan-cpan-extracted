use strict;
use warnings;
use Test::More;
use Test::Builder;
use List::Util qw(first);

package Sample::Resources;
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
    my ($result_ref, $ret_val) = @_;
    return sub {
        my ($id, %res) = @_;
        push(@$result_ref, map { sprintf("%s:%s", $_, $res{$_}) } grep { defined($res{$_}) } keys %res);
        return $ret_val;
    };
}

sub checkArray {
    my ($label, $result_ref, @exp_list) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    cmp_ok(int(@$result_ref), "==", int(@exp_list), sprintf("$label num == %d", int(@exp_list)));
    my @result = @$result_ref;
    foreach my $exp_str (@exp_list) {
        my $found_index = first { $result[$_] eq $exp_str } 0..$#result;
        ok(defined($found_index), "$label includes $exp_str");
        my @new_result = ();
        foreach my $i (0 .. $#result) {
            push @new_result, $result[$i] if $i != $found_index;
        }
        @result = @new_result;
    }
    cmp_ok(int(@result), "==", 0, "checked all $label");
}

sub checkResult {
    my ($result_ref, @exp_list) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    checkArray('result', $result_ref, @exp_list);
}

sub checkSelections {
    my ($selector, @exp_list) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    checkArray('selection', [$selector->selections], @exp_list);
}

sub checkSNum {
    my ($selector, $selection_num) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is(int($selector->selections), $selection_num, "$selection_num selections.");
}



note('Test for N-resource M-selection.');

{
    note('--- N-resource, 1-selection.');
    my $N = 5;
    my $s = new_ok('Async::Selector');
    my $rs = Sample::Resources->new($s, 1 .. $N);
    my @result = ();
    $s->select(collector(\@result, 1), 1 => 3, 2 => 4, 3 => 2, 4 => 9, 5 => 2);
    checkResult \@result;
    $rs->set(1 => "sk", 2 => "sas", 3 => "", 4 => "abcdefgh", 5 => "Y");
    checkResult \@result;
    $rs->set(1 => "ab", 2 => "asas", 3 => "BB",               5 => "ybb");
    checkResult \@result, qw(2:asas 3:BB 5:ybb);
    checkSelections $s;
    @result = ();
    $rs->set(map {$_ => "this_is_a_long_string"} 1 .. $N);
    cmp_ok(int(@result), "==", 0, "no result because the selection is removed.");

    @result = ();
    my $id = $s->select(collector(\@result, 0), 1 => 0, 2 => 3, 3 => 4);
    checkResult \@result, qw(1:this_is_a_long_string 2:this_is_a_long_string 3:this_is_a_long_string);
    @result = ();
    $rs->set(1 => "", 2 => "aa", 3 => "bb", 4 => "cc", 5 => "dd");
    checkResult \@result, qw(1:);
    checkSelections $s, $id;
    @result = ();
    $s->trigger(1 .. $N);
    checkResult \@result, qw(1:);
    @result = ();
    $s->trigger(3);
    checkResult \@result, qw(1:);
    @result = ();
    $rs->set(2 => "aaa", 3 => "bbbb", 4 => "ccccc", 5 => "dddddd");
    checkResult \@result, qw(1: 2:aaa 3:bbbb);

    note("--- -- if the triggered resource is not selected, the selection callback is not executed.");
    @result = ();
    $s->trigger(4, 5);
    checkResult \@result;

    $s->cancel($id);

    @result = ();
    $rs->set(map {$_ => ""} 1 .. $N);
    checkResult \@result;

    @result = ();
    $id = $s->select(collector(\@result, 0), 3 => 3, 4 => 4, 5 => 5);
    checkResult \@result;
    checkSelections $s, $id;
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
    note('--- 1-resource, M-selections');
    my $s = new_ok('Async::Selector');
    my $rs = Sample::Resources->new($s, 1);
    my @result = ();
    note('--- -- non-remove selections');
    my @ids = ();
    push @ids, $s->select(collector(\@result, 0), 1 => 1);
    push @ids, $s->select(collector(\@result, 0), 1 => 2);
    checkResult \@result;
    checkSelections $s, @ids;
    $rs->set(1 => "A");
    checkResult \@result, qw(1:A);
    checkSelections $s, @ids;
    @result = ();
    $rs->set(1 => "BB");
    checkResult \@result, qw(1:BB 1:BB);
    checkSelections $s, @ids;
    @result = ();
    $rs->set(1 => 'a');
    checkResult \@result, qw(1:a);
    checkSelections $s, @ids;
    $s->cancel(@ids);
    checkSelections $s;
    @result = ();
    $rs->set(1 => 'abcde');
    checkResult \@result;

    note('--- -- auto-remove selections');
    @result = ();
    $s->select(collector(\@result, 1), 1 => 4);
    checkResult \@result, qw(1:abcde);
    checkSNum $s, 0;
    $s->select(collector(\@result, 1), 1 => 6);
    checkResult \@result, qw(1:abcde);
    checkSNum $s, 1;
    $s->select(collector(\@result, 1), 1 => 7);
    checkResult \@result, qw(1:abcde);
    checkSNum $s, 2;
    $s->select(collector(\@result, 1), 1 => 3);
    checkResult \@result, qw(1:abcde 1:abcde);
    checkSNum $s, 2;
    $s->select(collector(\@result, 1), 1 => 8);
    checkResult \@result, qw(1:abcde 1:abcde);
    checkSNum $s, 3;
    $s->select(collector(\@result, 1), 1 => 9);
    checkResult \@result, qw(1:abcde 1:abcde);
    checkSNum $s, 4;
    @result = ();
    $rs->set(1 => "666666");
    checkResult \@result, "1:666666";
    checkSNum $s, 3;
    $rs->set(1 => "7777777");
    checkResult \@result, qw(1:666666 1:7777777);
    checkSNum $s, 2;
    $rs->set(1 => "88888888");
    checkResult \@result, qw(1:666666 1:7777777 1:88888888);
    checkSNum $s, 1;
    $rs->set(1 => "999999999");
    checkResult \@result, qw(1:666666 1:7777777 1:88888888 1:999999999);
    checkSNum $s, 0;
    @result = ();
    foreach my $num (10 .. 15) {
        $rs->set(1 => "A" x $num);
        checkResult \@result;
    }
    
    note('--- -- mix auto-remove and non-remove selections');
    $rs->set(1 => "");
    @result = ();
    @ids = ();
    push @ids, $s->select(collector(\@result, 0), 1 => 5);
    $s->select(collector(\@result, 1), 1 => 6);
    push @ids, $s->select(collector(\@result, 0), 1 => 7);
    $s->select(collector(\@result, 1), 1 => 8);
    checkResult \@result;
    @result = ();
    $rs->set(1 => "qqqq");
    checkResult \@result;
    checkSNum $s, 4;
    @result = ();
    $rs->set(1 => "wwwww");
    checkResult \@result, "1:wwwww";
    checkSNum $s, 4;
    @result = ();
    $rs->set(1 => "eeeeee");
    checkResult \@result, qw(1:eeeeee 1:eeeeee);
    checkSNum $s, 3;
    @result = ();
    $rs->set(1 => "rrrrrrr");
    checkResult \@result, qw(1:rrrrrrr 1:rrrrrrr);
    checkSNum $s, 3;
    @result = ();
    $rs->set(1 => "tttttttt");
    checkResult \@result, qw(1:tttttttt 1:tttttttt 1:tttttttt);
    checkSNum $s, 2;
    foreach my $num (9 .. 12) {
        @result = ();
        $rs->set(1 => ("A" x $num));
        checkResult \@result, ('1:' . ("A" x $num)) x 2;
    }
    $s->cancel(@ids);
    checkSNum $s, 0;
    foreach my $i (1 .. 3) {
        @result = ();
        $rs->set(1 => "PPPPPPPPPPPPPP");
        checkResult \@result;
    }
    
    note('--- -- cancel() some of the selections');
    $rs->set(1 => "a");
    @ids = ();
    @result = ();
    push @ids, $s->select(collector(\@result, 0), 1 => $_) foreach 1 .. 10;
    checkResult \@result, "1:a";
    checkSelections $s, @ids;
    @result = ();
    $s->cancel(@ids[2, 4, 5, 8]); ## 1 2 4 7 8 10
    checkSelections $s, @ids[0, 1, 3, 6, 7, 9];
    $rs->set(1 => "bbbbbb");
    checkResult(\@result, ("1:bbbbbb") x 3);
}

{
    note('--- N-resource, M-selections');
    my $s = new_ok('Async::Selector');
    my $rs = Sample::Resources->new($s, 1 .. 5);
    my @result = ();
    $s->select(collector(\@result, 1), 1 => 5, 2 => 5, 3 => 5);
    $s->select(collector(\@result, 1),         2 => 4, 3 => 4, 4 => 4);
    $s->select(collector(\@result, 1), 1 => 5,                 4 => 5, 5 => 5);
    $s->select(collector(\@result, 1),         2 => 0, 3 => 0, 4 => 3, 5 => 5);
    $s->select(collector(\@result, 1), 1 => 2,                 4 => 5, 5 => 2);
    $s->select(collector(\@result, 1),         2 => 4, 3 => 4);
    checkResult \@result, qw(2: 3:);
    checkSNum $s, 5;
    @result = ();
    $rs->set(1 => "aa", 5 => "aa");
    checkResult \@result, qw(1:aa 5:aa);
    checkSNum $s, 4;
    @result = ();
    $rs->set(3 => "AAAA", 4 => "AAAA");
    checkResult \@result, qw(3:AAAA 3:AAAA 4:AAAA);
    checkSNum $s, 2;
    @result = ();
    $rs->set(map {$_ => "bbbbbb"} 1 .. 5);
    checkResult \@result, qw(1:bbbbbb 2:bbbbbb 3:bbbbbb 1:bbbbbb 4:bbbbbb 5:bbbbbb);
    checkSNum $s, 0;
    @result = ();
    $rs->set(map {$_ => "cccccccccccc"} 1 .. 5);
    checkResult \@result;
    checkSNum $s, 0;
}

done_testing();

