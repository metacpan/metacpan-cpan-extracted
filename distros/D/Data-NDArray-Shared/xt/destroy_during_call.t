use strict;
use warnings;
use Test::More;
use Config;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'fork required' unless $Config{d_fork};
use Data::NDArray::Shared;

# An overloaded argument whose conversion explicitly calls $obj->DESTROY frees
# the C handle mid-method (DESTROY zeroes the IV and nda_destroy munmaps the
# segment).  Before the REEXTRACT fix the method kept using its stale handle
# pointer and dereferenced the munmap'ed segment -> SEGV; after it, the method
# re-reads the zeroed pointer and croaks ("destroyed during the call").
# fill/add_scalar convert the VALUE (SvNV), set converts the trailing value,
# get converts an INDEX (SvUV) -- each runs the magic between EXTRACT and the
# first use of the handle.  Per method one child: exit 0 = croaked (correct),
# exit 7 = ran on through freed memory, death by signal = crash.

{
    package Evil;
    use overload
        '0+' => sub { $_[0][0]->DESTROY; 0 },
        '""' => sub { $_[0][0]->DESTROY; '0' },
        fallback => 1;
}

my @cases = (
    [ fill       => sub { $_[0]->fill($_[1]) } ],
    [ add_scalar => sub { $_[0]->add_scalar($_[1]) } ],
    [ set        => sub { $_[0]->set(0, 0, $_[1]) } ],
    [ get        => sub { $_[0]->get($_[1], 0) } ],
);

for my $case (@cases) {
    my ($method, $call) = @$case;
    my $pid = fork();
    unless ($pid) {
        my $obj  = Data::NDArray::Shared->new(undef, "f64", 2, 3);
        my $evil = bless [$obj], 'Evil';
        my $ok = eval { $call->($obj, $evil); 1 };
        _exit($ok ? 7 : 0);   # 0 = croaked (correct), 7 = ran on through freed memory
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}
done_testing;
