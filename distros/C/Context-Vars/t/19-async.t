#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# An async sub keeps its own variables across await. Needs Future and
# Future::AsyncAwait, which this dist does not depend on; skipped without.

BEGIN {
    eval { require Future; require Future::AsyncAwait; 1 }
        or plan skip_all => 'Future::AsyncAwait is not installed';
}
use Future::AsyncAwait;
use Context::Vars qw($id);

ok(Context::Vars::_async_hooks(), 'the hooks are registered with Future::AsyncAwait');

my (%wait, @log);
sub d { defined $_[0] ? $_[0] : 'undef' }

async sub writer {
    my ($n) = @_;
    $id = "id$n";
    push @log, "$n start " . d($id);
    await $wait{"a$n"};
    push @log, "$n resumed " . d($id);
    $id = "again$n";
    for my $i (1) {
        await $wait{"b$n"};
        push @log, "$n in-loop " . d($id);
    }
    push @log, "$n end " . d($id);
    return $n;
}

$id = 'top';
$wait{$_} = Future->new for qw(a1 a2 b1 b2);

my @t = (writer(1), writer(2));
is($id, 'top', 'the caller reads its own while both tasks are suspended');
$wait{a2}->done; $wait{a1}->done;
is($id, 'top', 'a write made after await did not reach the caller');
$wait{b1}->done; $wait{b2}->done;
is_deeply([sort @log],
          [sort map { ("$_ start id$_", "$_ resumed id$_", "$_ in-loop again$_", "$_ end again$_") } 1, 2],
          'each task read its own value at every point, resumed in the opposite order it began');
is_deeply([map { $_->get } @t], [1, 2], 'both finished with their results');
is($id, 'top', 'the caller reads its own at the end');
is(Context::Vars::_depth(), 0, 'no scope is left open');

# A sub that only reads keeps the values it could see when it suspended.
{
    @log = ();
    my %w = map { $_ => Future->new } 1, 2;
    async sub reader { my $n = shift; push @log, "r$n start " . d($id); await $w{$n}; push @log, "r$n resumed " . d($id) }
    sub handler { my $n = shift; $id = "req$n"; reader($n) }
    my @r = (handler(1), handler(2));
    $w{2}->done; $w{1}->done;
    is_deeply([sort @log], ['r1 resumed req1', 'r1 start req1', 'r2 resumed req2', 'r2 start req2'],
              'an async sub with no write resumes with the values it suspended with');
}

# Dropped while suspended, and failing after resuming.
{
    my $x = Future->new;
    async sub abandoned { $id = 'abandoned'; await $x; $id = 'never'; return }
    { my $f = abandoned(); $f->cancel; }
    is($id, 'top', 'a cancelled task leaves the caller alone');

    my $w = Future->new;
    async sub dies_late { $id = 'dl'; await $w; die "late\n" }
    my $f = dies_late();
    $w->done;
    is(scalar $f->failure, "late\n", 'a die after await fails the future');
    is($id, 'top', 'and the caller reads its own');
    is(Context::Vars::_depth(), 0, 'with no scope open');
}

# Everything a suspended task held is let go once the tasks are gone.
@t = ();
is(Context::Vars::_live_holders(), 0, 'no holder is out once the tasks are gone');

done_testing;
