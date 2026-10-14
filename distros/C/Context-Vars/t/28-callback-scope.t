#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Deferred;
use Context::Vars qw($cs);

# A callback that assigns is a sub with a write, so it has a scope of its
# own. The next callback of the same task does not see the assignment unless
# it was queued from inside that callback, after it.

my $q = Deferred->new(wired => 1);
my @read;
sub task {
    $cs = 'task';
    $q->later(sub {
        $cs = 'first callback';
        $q->later(sub { push @read, "queued inside reads $cs" });
    });
    $q->later(sub { push @read, "queued beside reads $cs" });
}
task();
$q->drain;
is_deeply([sort @read], ['queued beside reads task', 'queued inside reads first callback'],
          'only the callback queued from inside, after the assignment, sees it');
is(Context::Vars::_depth(), 0, 'no context is left entered');

done_testing;
