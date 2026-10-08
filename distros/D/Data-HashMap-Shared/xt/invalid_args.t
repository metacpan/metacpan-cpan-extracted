use strict;
use warnings;
use Test::More;
use Data::HashMap::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

my $ok = eval { my $h = Data::HashMap::Shared::II->new(undef, 64); 1 };
ok $ok, 'baseline: valid args succeed' or diag "unexpected failure: $@";

# A bad argument may croak or yield an object but must not kill the process
# with a signal; each case runs in a child to detect that.

sub run_child {
    my ($label, $code) = @_;
    my $pid = fork // die;
    if ($pid == 0) {
        eval { $code->(); };
        exit 0;
    }
    waitpid($pid, 0);
    my $sig = $? & 127;
    is $sig, 0, "$label: no signal death (wstat=$?)";
}

run_child('embedded NUL path',     sub { Data::HashMap::Shared::II->new("/tmp/a\x00b.shm", 16) });
run_child('cap=0',                 sub { Data::HashMap::Shared::II->new(undef, 0) });
run_child('huge capacity',         sub { Data::HashMap::Shared::II->new(undef, 2 ** 50) });

SKIP: {
    skip 'no new_from_fd', 2 unless Data::HashMap::Shared::II->can('new_from_fd');
    run_child('new_from_fd(-1)', sub { Data::HashMap::Shared::II->new_from_fd(-1) });
    eval { Data::HashMap::Shared::II->new_from_fd(-1) };
    ok $@, "new_from_fd(-1) croaks (err: $@)";
}

done_testing;
