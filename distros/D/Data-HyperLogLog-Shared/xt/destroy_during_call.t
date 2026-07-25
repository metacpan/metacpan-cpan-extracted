use strict;
use warnings;
use Test::More;
use Config;
use Data::HyperLogLog::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Regression test for the REEXTRACT fix: argument magic (overload
# stringification here, since add/add_many read their items via SvPVbyte)
# that explicitly calls $obj->DESTROY frees the C handle mid-method.
# Before the fix the method went on to dereference the freed pointer and
# segfaulted; after it, REEXTRACT must croak cleanly. The child exits 0 on
# a clean croak, 7 if the method ran on through the freed handle, and dies
# by signal if it crashed -- only exit 0 is a pass.

{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 0 },
        fallback => 1;
}

for my $method (qw(add add_many)) {
    my $pid = fork();
    unless ($pid) {
        my $hll  = Data::HyperLogLog::Shared->new;   # anonymous, nothing to clean up
        my $evil = bless [$hll], 'Evil';
        my $ok   = $method eq 'add'
            ? eval { $hll->add($evil); 1 }
            : eval { $hll->add_many([$evil]); 1 };
        exit($ok ? 7 : 0);   # 0 = croaked (correct), 7 = ran on through freed memory
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

done_testing;
