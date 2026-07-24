use strict;
use warnings;
use Test::More;
use Config;
use Data::CountingBloomFilter::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Argument magic that explicitly calls $obj->DESTROY frees the C handle
# mid-method. Without the REEXTRACT fix the method dereferenced the freed
# pointer and segfaulted; with it the method must croak cleanly. The child
# exits 0 when the method croaked (correct) and 7 when it ran on through
# freed memory, so this test fails if the REEXTRACT calls are removed.

{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 0 },
        fallback => 1;
}

for my $method (qw(add contains count_of remove)) {
    my $pid = fork();
    unless ($pid) {
        my $obj  = Data::CountingBloomFilter::Shared->new(undef, 1000, 0.01);
        my $evil = bless [$obj], 'Evil';
        my $ok = eval { $obj->$method($evil); 1 };
        exit($ok ? 7 : 0);   # 0 = croaked (correct), 7 = ran on through freed memory
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

done_testing;
