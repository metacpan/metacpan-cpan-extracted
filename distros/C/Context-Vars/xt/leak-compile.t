#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($lk);

# Ten thousand subs compiled, called once and dropped. Nothing they opened
# stays open, and the process does not grow with them.

sub rss_kb {
    my $kb = `ps -o rss= -p $$ 2>/dev/null`;
    return $kb =~ /(\d+)/ ? $1 : undef;
}

$lk = 'base';
my $run = sub {
    my ($n) = @_;
    for my $i (1 .. $n) {
        my $s = eval "sub { \$lk = $i; \$lk }" or die $@;
        $s->() == $i or die "sub $i read the wrong value";
    }
};

$run->(2_000);
my $before = rss_kb();
$run->(10_000);
my $after = rss_kb();

is($lk, 'base', 'the caller reads its own afterwards');
is(Context::Vars::_depth(), 0, 'no scope is open');
is(Context::Vars::_live_holders(), 0, 'no holder is out');

SKIP: {
    skip 'ps gives no resident size here', 1 unless defined $before && defined $after;
    my $grew = $after - $before;
    diag "resident size before $before KB, after $after KB, grew $grew KB";
    cmp_ok($grew, '<', 2048, 'ten thousand more compiled and dropped subs grew the process by under 2 MB');
}

done_testing;
