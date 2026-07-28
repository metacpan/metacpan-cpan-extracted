use strict; use warnings; use Test::More;
use Config;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'fork required' unless $Config{d_fork};
use Data::SpatialHash::Shared;

# Argument magic (overload/tie) runs arbitrary Perl while the XSUB converts its
# arguments.  If that code calls $obj->DESTROY explicitly, the C handle is freed
# and the IV zeroed while the method is still mid-flight.  Without the
# REEXTRACT(self) calls in Shared.xs the method then dereferences the freed
# handle and SEGFAULTs; with them it must croak cleanly.  Each case runs in a
# forked child: exit 0 = croaked as required, exit 7 = ran on through freed
# memory, a signal = crash.  Removing the REEXTRACT calls must make this FAIL.

{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 0 },
        fallback => 1;
}

# method name => child code; $evil is passed where the method reads a number
# (SvNV/SvUV), so the '0+' overload fires mid-argument-conversion.
my %case = (
    insert       => sub { my ($o, $e) = @_; $o->insert($e, 0.5, 42) },
    move         => sub { my ($o, $e) = @_; $o->move($e, 1.5, 1.5) },
    query_radius => sub { my ($o, $e) = @_; $o->query_radius($e, 0.5, 1.0) },
    query_aabb   => sub { my ($o, $e) = @_; $o->query_aabb($e, 0, 1, 1) },
);

for my $method (sort keys %case) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $obj  = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);
        my $evil = bless [$obj], 'Evil';
        my $ok = eval { $case{$method}->($obj, $evil); 1 };
        _exit($ok ? 7 : 0);   # 0 = croaked (correct), 7 = used the freed handle
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

done_testing;
