#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 36;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'AnyEvent::Callback';
}

#
my ($called, $ecalled, $child_called, $child_ecalled, @res, @err) = (0) x 4;
my $cb = CB { $called++ };
isa_ok $cb => 'AnyEvent::Callback';
ok eval { $cb->(); 1 }, 'calling callback';
cmp_ok $called, '~~', 1, 'callback was called once';
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns => $_[0] };
    $cb->error();

    cmp_ok $#warns, '~~', 1, 'two warnings';
    like $warns[0], qr{error callback after result}, 'first warning';
    like $warns[1], qr{Uncaught error}, 'second warning';
}

#
($called, $ecalled, $child_called, $child_ecalled, @res, @err) = (0, 0, 0, 0);
$cb = CB sub { $called++ }, sub { $ecalled++ };
isa_ok $cb => 'AnyEvent::Callback';
$cb->error(123);
cmp_ok $ecalled, '~~', 1, 'error callback was touched';
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns => $_[0] };
    $cb->(456);

    cmp_ok $#warns, '~~', 0, 'one warning';
    like $warns[0], qr{result callback after error}, 'warning text';
}
cmp_ok $ecalled, '~~', 1, 'error callback was touched once';
cmp_ok $called, '~~', 0, 'result callback was not touched';

#
($called, $ecalled, $child_called, $child_ecalled, @res, @err) = (0, 0, 0, 0);
$cb = CB sub { $called++ }, sub { $ecalled++ };
isa_ok $cb => 'AnyEvent::Callback';
$cb->(123);
cmp_ok $called, '~~', 1, 'result callback was touched';
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns => $_[0] };
    $cb->error(456);

    cmp_ok $#warns, '~~', 1, 'warning twice';
    like $warns[0], qr{error callback after result}, 'first warning';
    like $warns[1], qr{Uncaught error}, 'first warning';
}
cmp_ok $ecalled, '~~', 0, 'error callback was not touched';
cmp_ok $called, '~~', 1, 'result callback was touched once';

#
($called, $ecalled, $child_called, $child_ecalled, @res, @err) = (0, 0, 0, 0);
$cb = CB sub { $called++; @res = @_ }, sub { $ecalled++; @err = @_ };
my $cb_child = $cb->CB(sub { $child_called++ });
undef $cb_child;
cmp_ok $called, '~~', 0, "result callback wasn't touched";
cmp_ok $ecalled, '~~', 1, "error callback wasn touched once";
cmp_ok $child_called, '~~', 0, "child result callback wasn't touched";
cmp_ok $child_ecalled, '~~', 0, "child error callback wasn't touched";
like $err[0], qr{no one touched registered}, 'autotouch error callback';


#
($called, $ecalled, $child_called, $child_ecalled, @res, @err) = (0, 0, 0, 0);
$cb = CB sub { $called++; @res = @_ }, sub { $ecalled++; @err = @_ };
$cb_child = $cb->CB(sub { $child_called++ });
$cb_child->error(12345);
is $err[0], '12345', 'autotouch error callback';
cmp_ok $called, '~~', 0, "result callback wasn't touched";
cmp_ok $ecalled, '~~', 1, "error callback was touched once";
cmp_ok $child_called, '~~', 0, "child result callback wasn't touched";
cmp_ok $child_ecalled, '~~', 0, "child error callback wasn't touched";

{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns => $_[0] };
    $cb_child->(456);

    cmp_ok $#warns, '~~', 0, 'one warning';
    like $warns[0], qr{result callback after error}, 'warning text';
}

cmp_ok $called, '~~', 0, "result callback wasn't touched";
cmp_ok $ecalled, '~~', 1, "error callback was touched once";
cmp_ok $child_called, '~~', 0, "child result callback wasn't touched";
cmp_ok $child_ecalled, '~~', 0, "child error callback wasn't touched";
