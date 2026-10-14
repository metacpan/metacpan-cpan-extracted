#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($cr);

# capture keeps the values of its moment; run puts them back for the code it
# calls, and only for that code.

my ($ctx, $after_capture);
sub take {
    $cr = 'A';
    $ctx = Context::Vars->capture;
    $cr = 'B';
    $after_capture = $cr;
}
take();
isa_ok($ctx, 'Context::Vars::Context', 'capture returns');
is($after_capture, 'B', 'the sub went on with its own later value');

$cr = 'caller';
my $inside = $ctx->run(sub { $cr });
is($inside, 'A', 'run reads the value at the moment of capture, not the later B');
is($cr, 'caller', 'and the caller reads its own value afterwards');

# What run passes and returns.
is_deeply([$ctx->run(sub { @_ }, 1, 2, 3)], [1, 2, 3], 'arguments are passed through');
is_deeply([$ctx->run(sub { ('x', 'y') })], ['x', 'y'], 'a list is returned in list context');
my $s = $ctx->run(sub { wantarray ? 'list' : defined(wantarray) ? 'scalar' : 'void' });
is($s, 'scalar', 'the code is called in scalar context when run is');
my @l = $ctx->run(sub { wantarray ? 'list' : 'scalar' });
is_deeply(\@l, ['list'], 'and in list context when run is');
my $void;
$ctx->run(sub { $void = defined(wantarray) ? 'not void' : 'void' });
is($void, 'void', 'and in void context when run is');
is_deeply([$ctx->run(sub { return })], [], 'an empty return is an empty list');
my $big = $ctx->run(sub { [map { $_ * 2 } 1 .. 1000] });
is(scalar @$big, 1000, 'a reference to a large result comes back whole');
my @many = $ctx->run(sub { 1 .. 5000 });
is(scalar @many, 5000, 'five thousand values on the stack come back');
is($many[-1], 5000, 'in order');
my $arg_modified = 'before';
$ctx->run(sub { $_[0] = 'after' }, $arg_modified);
is($arg_modified, 'after', 'arguments are aliases, as for any call');

# A die.
ok(!eval { $ctx->run(sub { die "in run\n" }); 1 }, 'a die in the code propagates');
is($@, "in run\n", 'unchanged');
is($cr, 'caller', 'and the caller\'s value is back');
is(Context::Vars::_depth(), 0, 'with no context left entered');

# Nested runs, of two different contexts.
my $other;
sub take_other { $cr = 'O'; $other = Context::Vars->capture }
take_other();
my @trace = $ctx->run(sub {
    my @t = ($cr);
    push @t, $other->run(sub { $cr });
    push @t, $cr;
    @t;
});
is_deeply(\@trace, ['A', 'O', 'A'], 'a run inside a run reads its own, then the outer one\'s again');

# A context captured with nothing set.
{
    my $empty = Context::Vars->capture;
    my $r = system($^X, (map { "-I$_" } grep { !ref } @INC), '-e', q{
        use Context::Vars qw($cr);
        my $empty = Context::Vars->capture;
        my $r = $empty->run(sub { defined $cr ? 'set' : 'unset' });
        exit($r eq 'unset' ? 0 : 1);
    });
    is($r >> 8, 0, 'a capture taken with nothing set reads nothing set');
}

# The code given must be code.
ok(!eval { $ctx->run('not code'); 1 }, 'run refuses something that is not code');
like($@, qr/^Context::Vars::Context::run: not a code reference/, 'by name');

is(Context::Vars::_depth(), 0, 'no context is left entered');

done_testing;
