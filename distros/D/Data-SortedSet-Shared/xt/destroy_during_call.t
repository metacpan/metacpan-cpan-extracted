use strict;
use warnings;
use Test::More;
use Config;
use Data::SortedSet::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# An overloaded argument whose numeric conversion explicitly DESTROYs the set.
# The method has already EXTRACTed the C handle when the magic runs, so without
# the REEXTRACT re-check it would dereference a freed pointer (segfault); with
# it, the method must croak cleanly. exit 0 = croaked (correct), exit 7 = ran
# on through freed memory.
{
    package Evil;
    use overload
        '0+'   => sub { $_[0][0]->DESTROY; 0 },
        '""'   => sub { $_[0][0]->DESTROY; '0' },
        'bool' => sub { $_[0][0]->DESTROY; 1 },   # SvTRUE on the option value
        fallback => 1;
}

for my $method (qw(range_by_rank range_by_score rev_range_by_rank rev_range_by_score)) {
    my $pid = fork();
    unless ($pid) {
        my $obj = Data::SortedSet::Shared->new(undef, 16);
        $obj->add(1, 1.5);
        $obj->add(2, 2.5);
        $obj->add(3, 3.5);
        my $evil = bless [$obj], 'Evil';
        my $ok = eval {
            # The guarded magic is in ss_parse_range_opts, which runs on the
            # trailing OPTION arguments -- start/stop are IV and are converted
            # by xsubpp before CODE, so passing $evil there exercises nothing.
            # Only "withscores" is accepted here (limit/offset are passed NULL).
            if    ($method eq 'range_by_rank')      { $obj->range_by_rank(0, -1, withscores => $evil) }
            elsif ($method eq 'rev_range_by_rank')  { $obj->rev_range_by_rank(0, -1, withscores => $evil) }
            elsif ($method eq 'range_by_score')     { $obj->range_by_score(0, 10, withscores => $evil) }
            else                                    { $obj->rev_range_by_score(10, 0, withscores => $evil) }
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
