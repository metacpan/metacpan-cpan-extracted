#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Containers across await, in a new thread, and what an access costs.
use Config;
use Time::HiRes qw(time);
use Context::Vars qw(%seen);

# S11
SKIP: {
    skip 'S11: Future::AsyncAwait not installed', 2 unless eval { require Future; require Future::AsyncAwait; Future::AsyncAwait->import; 1 };
    my %w = map { $_ => Future->new } 1, 2;
    my @log;
    eval q{
        use Future::AsyncAwait;
        async sub task { my $n = shift; $seen{id} = "id$n"; $seen{nest}{n} = $n; await $w{$n}; push @log, "$n:$seen{id}:$seen{nest}{n}" }
        1;
    } or die $@;
    %seen = (id => 'top');
    my @t = (task(1), task(2));
    $w{2}->done; $w{1}->done;
    is_deeply([sort @log], ['1:id1:1', '2:id2:2'], 'S11: each async task keeps its own hash, nested level included');
    is($seen{id}, 'top', 'S11: and the caller its own');
}

# S12
SKIP: {
    skip 'S12: no ithreads', 1 unless $Config{useithreads} && eval { require threads; 1 };
    %seen = (parent => 1);
    my @got = threads->create({ context => 'list' }, sub {
        my $before = join ',', sort keys %seen;
        Context::Vars::_t_scope(sub { $seen{child} = 1 });
        return ($before);
    })->join;
    is($got[0], '', 'S12: a new thread starts with an empty hash');
}

# S13 (estimates from the Perl proxies)
sub ns { my ($code, $n) = @_; my $t = time; $code->() for 1 .. $n; (time - $t) * 1e9 / $n }
my %plain = (a => 1, n => { b => 1 });
Context::Vars::_t_scope(sub {
    %seen = (a => 1, n => { b => 1 });
    my $n = 2_000;
    my %r = (
        'plain read'          => ns(sub { my $x = $plain{a} }, $n),
        'proxy read'          => ns(sub { my $x = $seen{a} }, $n),
        'plain write'         => ns(sub { $plain{a} = 2 }, $n),
        'proxy write'         => ns(sub { $seen{a} = 2 }, $n),
        'plain nested write'  => ns(sub { $plain{n}{b} = 2 }, $n),
        'proxy nested write'  => ns(sub { $seen{n}{b} = 2 }, $n),
    );
    diag sprintf "S13 %-20s %8.0f ns", $_, $r{$_} for sort keys %r;
});
ok(1, 'S13: recorded');
done_testing;
