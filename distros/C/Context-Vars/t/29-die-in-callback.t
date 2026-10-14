#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Deferred;
use Context::Vars qw($dc);

# A callback that dies, inside the queue's eval, takes nothing with it: the
# next callback, of another task, reads its own value.

my $q = Deferred->new(wired => 1);
my @read;
sub task {
    my ($name, $die) = @_;
    $dc = $name;
    $q->later(sub { push @read, "$name reads $dc"; die "$name died\n" if $die });
}
task('A', 1);
task('B', 0);
task('C', 1);
task('D', 0);
$q->run_all;
is_deeply(\@read, ['A reads A', 'B reads B', 'C reads C', 'D reads D'], 'each read its own, around the deaths');
is_deeply([$q->errors], ["A died\n", "C died\n"], 'the two deaths reached the queue');
is(Context::Vars::_depth(), 0, 'no context is left entered after them');
is(Context::Vars::_live_holders(), 0, 'and no holder is out');

done_testing;
