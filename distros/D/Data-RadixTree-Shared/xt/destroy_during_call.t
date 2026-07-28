use strict;
use warnings;
use Test::More;
use Config;
use Data::RadixTree::Shared;

# Argument magic that calls $obj->DESTROY frees the C handle mid-method.
# Without the REEXTRACT fix the method dereferences the freed handle and
# segfaults; with it, the method must croak cleanly ("destroyed").
# Each case runs in a forked child: exit 0 = croaked (correct),
# exit 7 = ran on through freed memory, signal = crash.

plan skip_all => 'fork required' unless $Config{d_fork};

{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 1 },
        fallback => 1;
}

for my $method (qw(insert lookup exists longest_prefix)) {
    my $pid = fork();
    unless ($pid) {
        my $t    = Data::RadixTree::Shared->new(undef, 4096, 65536);
        my $evil = bless [$t], 'Evil';
        my $ok   = eval {
            if ($method eq 'insert') {
                $t->insert($evil, 1);       # key stringified -> DESTROY
            } else {
                $t->$method($evil);         # key stringified -> DESTROY
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
