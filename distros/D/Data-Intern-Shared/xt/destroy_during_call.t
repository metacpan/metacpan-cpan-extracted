use strict;
use warnings;
use Test::More;
use Config;
use Data::Intern::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Stringification magic on the argument explicitly DESTROYs the object whose
# C handle the method is using. Before the REEXTRACT fix the method went on to
# dereference the freed handle and SEGFAULTED; after it, the method must croak
# cleanly ("destroyed" per t/01-basic.t). Child exit 7 means the method ran on
# through freed memory: the test fails either way if REEXTRACT is removed.
{
    package Evil;
    use overload '""' => sub { $_[0][0]->DESTROY; 'k' }, fallback => 1;
}

for my $method (qw(exists id_of intern)) {
    my $pid = fork();
    unless ($pid) {
        my $obj = Data::Intern::Shared->new(undef, 1000);
        $obj->intern('seed');                # non-empty segment
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
