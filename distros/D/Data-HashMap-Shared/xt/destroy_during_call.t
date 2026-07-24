use strict;
use warnings;
use Test::More;
use Config;
use POSIX ();
use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::SS;

plan skip_all => 'fork required' unless $Config{d_fork};

# An overloaded key argument whose stringification calls $map->DESTROY frees
# the C handle between EXTRACT_MAP and the first use of h.  Without the
# REEXTRACT_MAP guard the method dereferences the freed pointer and crashes;
# with it, the method must croak cleanly ("object destroyed during the call").
# Each case runs in a forked child: exit 0 = croaked (correct), exit 7 = the
# method ran on through freed memory, any signal = crash.

{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 0 },
        fallback => 1;
}

my @cases = (
    # [ name, constructor, coderef calling the method with the evil argument ]
    ['SI::put',  sub { Data::HashMap::Shared::SI->new(undef, 64) },
        sub { my ($m, $e) = @_; $m->put($e, 42) }],
    ['SI::get',  sub { Data::HashMap::Shared::SI->new(undef, 64) },
        sub { my ($m, $e) = @_; $m->get($e) }],
    ['SI::incr', sub { Data::HashMap::Shared::SI->new(undef, 64) },
        sub { my ($m, $e) = @_; $m->incr($e) }],
    ['SS::put',  sub { Data::HashMap::Shared::SS->new(undef, 64) },
        sub { my ($m, $e) = @_; $m->put($e, 'v') }],
    ['SS::get',  sub { Data::HashMap::Shared::SS->new(undef, 64) },
        sub { my ($m, $e) = @_; $m->get($e) }],
);

for my $case (@cases) {
    my ($name, $new, $call) = @$case;
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    unless ($pid) {
        my $obj  = $new->();
        my $evil = bless [$obj], 'Evil';
        my $ok = eval { $call->($obj, $evil); 1 };
        POSIX::_exit($ok ? 7 : 0);   # 0 = croaked (correct), 7 = ran on through freed memory
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$name: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$name: croaks instead of using the freed handle";
}

done_testing;
