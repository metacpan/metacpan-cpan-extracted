use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

# A batch receive that hits an allocation failure after messages have already
# left the queue must still hand them over. Croaking there unwound the stack
# and lost every message the call had taken: their clients waited forever for
# replies that could now never be sent.
#
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

for my $method (qw(recv_multi drain)) {
    unlink $path;
    perl_run(qq{use Data::ReqRep::Shared; Data::ReqRep::Shared->new($geom)});
    perl_run(q{use Data::ReqRep::Shared::Client;
        my $c = Data::ReqRep::Shared::Client->new("} . $path . q{");
        $c->send($_) for "aaaaaaaaaa", ("B" x 77777), "cccccccccc";});

    my $call = $method eq 'drain' ? '$s->drain(10)' : '$s->recv_multi(10)';
    my $out = perl_run(
        qq{use Data::ReqRep::Shared; my \$s = Data::ReqRep::Shared->new($geom);
           my \@got = eval { $call }; print "CROAK\\n" if \$@;
           print "got=", scalar(\@got) / 2, " lens=", join(",", map { length \$got[\$_] } grep { !(\$_ % 2) } 0 .. \$#got),
                 " queued=", \$s->size, "\\n";},
        LD_PRELOAD => $shim);

    unlike $out, qr/CROAK/, "$method: an allocation failure mid-batch does not croak";
    like   $out, qr/got=2 lens=10,77777 queued=1/,
        "$method: both consumed messages are delivered, the rest stay queued"
        or diag $out;
}

done_testing;
