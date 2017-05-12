use strict;
use warnings;
use Test::More;
use Test::Warn;

BEGIN {
    use_ok('Async::Selector');
}

my $s = new_ok('Async::Selector');

$s->register(
    a => sub { my $in = shift;  return defined($in) ? 'A' : undef },
    b => sub { my $in = shift;  return defined($in) ? undef : 'B' },
    c => sub { my $in = shift;  return defined($in) ? 'C' : undef },
);

my $fired = 0;
$s->select(sub {
    my ($id, %res) = @_;
    $fired = 1;
    is_deeply(\%res, {a => undef, b => 'B', c => undef}, "Only b is ready");
    return 1;
}, a => undef, b => undef, c => undef);
is($fired, 1, 'selection fired immediately');
is(int($s->selections), 0, "no selection");

$fired = 0;
$s->select_et(sub {
    my ($id, %res) = @_;
    $fired = 1;
    is_deeply(\%res, {a => undef, b => 'B', c => undef}, 'Only b is ready');
    return 1;
}, a => undef, b => undef, c => undef);
is($fired, 0, 'selection not fired because its ET');
$s->trigger(qw(a b c));
is($fired, 1, "selection fired");
is(int($s->selections), 0, "no selection");


$fired = 0;
$s->select(sub {
    my ($id, %res) = @_;
    $fired = 1;
    is_deeply(\%res, {a => 'A', b => undef, c => 'C'}, 'a and c are ready');
    return 1;
}, a => '', b => 0, c => '');
is($fired, 1, 'selection fired immediately');
is(int($s->selections), 0, "no selection");

$fired = 0;
$s->select_et(sub {
    my ($id, %res) = @_;
    $fired = 1;
    is_deeply(\%res, {a => 'A', b => undef, c => 'C'}, 'a and c are ready');
    return 1;
}, a => '', b => 0, c => '');
is($fired, 0, 'selection not fired because its ET');
$s->trigger(qw(a b c));
is($fired, 1, 'selection fired');
is(int($s->selections), 0, "no selection");

done_testing();
