use strict;
use warnings;
use Test::More;
use Config;
use Data::Stack::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Argument magic that explicitly calls $obj->DESTROY frees the C handle
# mid-method. Without the REEXTRACT_STK guard the method goes on to
# dereference the freed (munmap'ed) handle and crashes; with it the
# method must croak cleanly.
{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 0 },
        fallback => 1;
}

# name, constructor, method call ($obj, $evil)
my @cases = (
    [ 'Int::pop_wait',
      sub { Data::Stack::Shared::Int->new(undef, 4) },
      sub { my ($obj, $evil) = @_; $obj->pop_wait($evil) } ],
    [ 'Int::push_wait',
      sub { Data::Stack::Shared::Int->new(undef, 4) },
      sub { my ($obj, $evil) = @_; $obj->push_wait(1, $evil) } ],
    [ 'Str::push',
      sub { Data::Stack::Shared::Str->new(undef, 4, 32) },
      sub { my ($obj, $evil) = @_; $obj->push($evil) } ],
    [ 'Str::pop_wait',
      sub { Data::Stack::Shared::Str->new(undef, 4, 32) },
      sub { my ($obj, $evil) = @_; $obj->pop_wait($evil) } ],
);

for my $case (@cases) {
    my ($method, $make, $call) = @$case;
    my $pid = fork();
    unless ($pid) {
        my $obj  = $make->();
        my $evil = bless [$obj], 'Evil';
        my $ok = eval { $call->($obj, $evil); 1 };
        exit($ok ? 7 : 0);   # 0 = croaked (correct), 7 = ran on through freed memory
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

done_testing;
