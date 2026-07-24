use strict;
use warnings;
use Test::More;
use Config;
use Data::IntervalTree::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

{
    package Evil;
    # add() resolves its optional id argument with SvUV between EXTRACT and
    # REEXTRACT: numeric magic ('0+') fires there and destroys the handle.
    use overload '0+' => sub { $_[0][0]->DESTROY; 0 }, fallback => 1;
}

for my $method (qw(add)) {
    my $pid = fork();
    unless ($pid) {
        my $obj  = Data::IntervalTree::Shared->new(undef, 16);
        my $evil = bless [$obj], 'Evil';
        my $ok   = eval { $obj->$method(1, 2, $evil); 1 };
        exit($ok ? 7 : 0);   # 0 = croaked (correct), 7 = ran on through freed memory
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

done_testing;
