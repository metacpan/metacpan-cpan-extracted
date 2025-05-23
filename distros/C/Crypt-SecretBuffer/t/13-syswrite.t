use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use IO::Handle;
use Crypt::SecretBuffer qw(secret);

subtest 'syswrite to pipe' => sub {
    my ($r, $w) = pipe_with_data();
    my $buf = Crypt::SecretBuffer->new('secret data');
    my $written = $buf->syswrite($w);
    is($written, length('secret data'), 'wrote all bytes');
    close $w;
    local $/; my $got = <$r>;
    is($got, 'secret data', 'read back data');
    close $r;
};

subtest 'syswrite with offset/count' => sub {
    my ($r, $w) = pipe_with_data();
    my $buf = Crypt::SecretBuffer->new('abcdefgh');
    my $written = $buf->syswrite($w, 4, 2); # write cdef
    is($written, 4, 'wrote subset');
    close $w; local $/; my $got = <$r>;
    is($got, 'cdef', 'subset received');
    close $r;
};

done_testing;

