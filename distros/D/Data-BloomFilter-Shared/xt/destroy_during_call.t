use strict;
use warnings;
use Test::More;
use Config;
use Data::BloomFilter::Shared;
plan skip_all => 'fork required' unless $Config{d_fork};

# Argument magic that explicitly calls $obj->DESTROY frees the C handle
# mid-method. Before the REEXTRACT fix the method dereferenced a freed
# pointer and SEGFAULTED; after it, the method must croak cleanly.
# Exit 0 = croaked (correct), exit 7 = ran on through freed memory.

{ package Evil;
  use overload '""' => sub { $_[0][0]->DESTROY; 'k' }, fallback => 1; }

for my $method (qw(add contains add_many)) {
    my $pid = fork();
    unless ($pid) {
        my $obj  = Data::BloomFilter::Shared->new(undef, 100, 0.01);
        my $evil = bless [$obj], 'Evil';
        my $ok = eval {
            if ($method eq 'add_many') {
                $obj->add_many([$evil]);
            }
            else {
                $obj->$method($evil);
            }
            1;
        };
        exit($ok ? 7 : 0);
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}
done_testing;
