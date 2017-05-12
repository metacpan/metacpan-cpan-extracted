package Async::Selector::testutils;
use strict;
use warnings;
use base qw(Exporter);
use Test::Builder;
use Test::More;
use List::Util qw(first);

our @EXPORT = qw(checkCond checkArray checkWatchers checkWNum checkRNum);
our @EXPORT_OK = @EXPORT;

sub checkCond {
    my ($w, $exp_res, $exp_cond, $case) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $case ||= "";
    is_deeply([sort {$a cmp $b} $w->resources], $exp_res, $case . ': resources()');
    is_deeply({$w->conditions}, $exp_cond, $case . ': conditions()');
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

sub checkWatchers {
    my ($selector, @exp_list) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    checkArray('watchers', [$selector->watchers], @exp_list);
}

sub checkWNum {
    my ($selector, $watcher_num) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is(int($selector->watchers), $watcher_num, "$watcher_num watchers.");
}

sub checkRNum {
    my ($selector, $resource_num) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is(int($selector->resources), $resource_num, "$resource_num resources.");
}


1;
