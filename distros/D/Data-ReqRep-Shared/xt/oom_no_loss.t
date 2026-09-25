use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

# Fail exactly one malloc of a distinctive size, so the only allocation that
# fails is the per-item copy of the one oversized message.

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $cc = $Config{cc} or plan skip_all => 'no C compiler';

my $dir  = tempdir(CLEANUP => 1);
my $shim = "$dir/shim.so";
{
    open my $fh, '>', "$dir/shim.c" or die $!;
    print {$fh} <<'C';
#include <stddef.h>
extern void *__libc_malloc(size_t);
static int fired;
void *malloc(size_t n) {
    if (n == 77777 && !fired) { fired = 1; return 0; }
    return __libc_malloc(n);
}
C
    close $fh;
    system($cc, '-shared', '-fPIC', '-o', $shim, "$dir/shim.c") == 0
        or plan skip_all => "cannot build the malloc shim with $cc";
}

my $path  = "$dir/q.shm";
my @inc   = map { "-I$_" } @INC;
my $geom  = qq{"$path", 16, 8, 256, 1 << 20};

sub perl_run {
    my ($code, %env) = @_;
    local @ENV{keys %env} = values %env;
    my $out = qx{$^X @inc -e '$code' 2>&1};
    return $out;
}
plan skip_all => "the malloc shim does not load here (it needs glibc's __libc_malloc)"
    unless perl_run(q{print "ok"}, LD_PRELOAD => $shim) =~ /ok\z/;

for my $method (qw(recv_multi drain)) {
    unlink $path;
    perl_run(qq{use Data::ReqRep::Shared; Data::ReqRep::Shared->new($geom)});
    perl_run(q{use Data::ReqRep::Shared::Client; use POSIX ();
        my $c = Data::ReqRep::Shared::Client->new("} . $path . q{");
        $c->send($_) for "aaaaaaaaaa", ("B" x 77777), "cccccccccc";
        POSIX::_exit(0);});

    my $call = $method eq 'drain' ? '$s->drain(10)' : '$s->recv_multi(10)';
    my $out = perl_run(
        qq{use Data::ReqRep::Shared; my \$s = Data::ReqRep::Shared->new($geom);
           my \@got = eval { $call }; print "CROAK\\n" if \$@;
           print "got=", scalar(\@got) / 2, " lens=", join(",", map { length \$got[\$_] } grep { !(\$_ % 2) } 0 .. \$#got),
                 " replied=", scalar(grep { \$s->reply(\$got[\$_], "r") } grep { \$_ % 2 } 0 .. \$#got),
                 " queued=", \$s->size, "\\n";},
        LD_PRELOAD => $shim);

    unlike $out, qr/CROAK/, "$method: an allocation failure mid-batch does not croak";
    like   $out, qr/got=2 lens=10,77777 replied=2 queued=1/,
        "$method: both consumed messages are delivered and can be replied to, the rest stay queued"
        or diag $out;
}
# A 40 MiB reply grows the copy buffer to 64 MiB in one realloc; fail every such realloc.
{
    my $shim2 = "$dir/shim2.so";
    open my $fh, '>', "$dir/shim2.c" or die $!;
    print {$fh} <<'C';
#include <stddef.h>
extern void *__libc_realloc(void *, size_t);
void *realloc(void *p, size_t n) {
    if (n == 67108864) return 0;
    return __libc_realloc(p, n);
}
C
    close $fh;
    system($cc, '-shared', '-fPIC', '-o', $shim2, "$dir/shim2.c") == 0 or die "cannot build shim2";

    my $rpath = "$dir/req.shm";
    require Data::ReqRep::Shared;
    my $srv = Data::ReqRep::Shared->new($rpath, 4, 1, 40 << 20);
    my $pid = fork // die $!;
    if (!$pid) {
        for my $reply ('R' x (40 << 20), 'small') {
            my (undef, $id) = $srv->recv_wait(10) or last;
            $srv->reply($id, $reply);
        }
        require POSIX;
        POSIX::_exit(0);
    }
    my $out = perl_run(
        qq{use Data::ReqRep::Shared::Client; my \$c = Data::ReqRep::Shared::Client->new("$rpath");
           my \$r = eval { \$c->req("q") }; (my \$e = \$\@) =~ s/ at .*//s;
           print "err=[\$e] pending=", \$c->pending;
           my \$again = eval { \$c->req_wait("q2", 5) };
           print " again=", defined \$again ? \$again : "undef", "\\n";},
        LD_PRELOAD => $shim2);
    waitpid $pid, 0;
    like $out, qr/err=\[.*out of memory\]/, 'req: a reply that cannot be copied croaks "out of memory"'
        or diag $out;
    like $out, qr/pending=0 again=small/, '  and frees its slot for the next request' or diag $out;
}

done_testing;
