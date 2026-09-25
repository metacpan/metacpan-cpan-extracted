use strict;
use warnings;
use Test::More;
use Data::ReqRep::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

my $ok = eval { my $h = Data::ReqRep::Shared->new(undef, 64, 32, 64); 1 };
ok $ok, 'baseline: valid args succeed' or diag "unexpected failure: $@";

sub run_child {
    my ($label, $code) = @_;
    my $pid = fork // die;
    if ($pid == 0) {
        eval { $code->(); };
        exit 0;  # any croak is fine — we only care about no signal
    }
    waitpid($pid, 0);
    my $sig = $? & 127;
    is $sig, 0, "$label: no signal death (wstat=$?)";
}

run_child('embedded NUL path',     sub { Data::ReqRep::Shared->new("/tmp/a\x00b.shm", 16) });

run_child('cap=0',                 sub { Data::ReqRep::Shared->new(undef, 0) });

run_child('huge capacity',         sub { Data::ReqRep::Shared->new(undef, 2 ** 50) });

SKIP: {
    skip 'no new_from_fd', 2 unless Data::ReqRep::Shared->can('new_from_fd');
    run_child('new_from_fd(-1)', sub { Data::ReqRep::Shared->new_from_fd(-1) });
    eval { Data::ReqRep::Shared->new_from_fd(-1) };
    ok $@, "new_from_fd(-1) croaks (err: $@)";
}

done_testing;
