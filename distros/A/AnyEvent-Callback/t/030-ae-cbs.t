#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 28;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'AnyEvent::Callback';
    use_ok 'AnyEvent';
}

for my $cv (AE::cv) {
    my @res;
    my $cbs = CBS;
    $cbs->wait(sub { @res = @_; $cv->send });

    $cv->recv;

    cmp_ok scalar(@res), '~~', 0, 'empty list';
}

for my $cv (AE::cv) {
    my @res;
    my $cbs = CBS;
    my @timers;

    for (1 .. 10) {
        push @timers => AE::timer rand .1, 0, $cbs->cb;
    }
    push @timers => AE::timer 0, 0, $cbs->cb;

    $cbs->wait(sub { @res = @_; $cv->send });

    {
        $cbs->cb;
    }

    $cv->recv;

    cmp_ok scalar(@res), '~~', 12, 'stack list';
    for (0 .. $#res) {
        isa_ok $res[$_] => 'AnyEvent::Callback::Stack::Result';
        if ($_ < $#res) {
            ok !$res[$_]->is_error, 'not error' ;
        } else {
            ok $res[$_]->is_error, 'forgotten callback';
        }
    }
}
