use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Int;

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $cc = $Config{cc} or plan skip_all => 'no C compiler';
my $dir = tempdir(CLEANUP => 1);

open my $fh, '>', "$dir/swap.c" or die $!;
print {$fh} <<'C';
#define _GNU_SOURCE
#define _FILE_OFFSET_BITS 64
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

/* Replace the pathname as the constructor closes the file it already mapped. */
int close(int fd) {
    static int swapped;
    const char *path = getenv("REQREP_SWAP_PATH");
    const char *replacement = getenv("REQREP_SWAP_FILE");
    struct stat a, b;
    if (!swapped && path && replacement && fstat(fd, &a) == 0 && stat(path, &b) == 0
            && S_ISREG(a.st_mode) && a.st_dev == b.st_dev && a.st_ino == b.st_ino) {
        swapped = 1;
        if (rename(replacement, path) != 0) _exit(90);
    }
    return ((int (*)(int))dlsym(RTLD_NEXT, "close"))(fd);
}
C
close $fh;
system($cc, '-shared', '-fPIC', '-o', "$dir/swap.so", "$dir/swap.c", '-ldl') == 0
    or plan skip_all => "cannot build the shim with $cc";

open $fh, '>', "$dir/open.pl" or die $!;
print {$fh} <<'P';
use strict;
use warnings;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Int;
my ($class, $path, $replacement) = @ARGV;
my @extra = $class =~ /::Int$/ ? () : (64);
my $h = $class->new($path, 4, 2, @extra);
die "replacement did not run\n" if -e $replacement;
$h->unlink;
print -e $path ? "replacement survives\n" : "replacement removed\n";
P
close $fh;

for my $class (qw(Data::ReqRep::Shared Data::ReqRep::Shared::Int)) {
    my @extra = $class =~ /::Int$/ ? () : (64);
    for my $case (qw(create attach recover)) {
        my $path = "$dir/channel.shm";
        my $replacement = "$dir/replacement.shm";
        unlink $path;
        $class->new($replacement, 4, 2, @extra);
        if ($case ne 'create') {
            $class->new($path, 4, 2, @extra);
            if ($case eq 'recover') {
                my $size = -s $path;
                open my $zero, '>', $path or die $!;
                truncate($zero, $size) or die $!;
                close $zero;
            }
        }
        local $ENV{REQREP_SWAP_PATH} = $path;
        local $ENV{REQREP_SWAP_FILE} = $replacement;
        local $ENV{LD_PRELOAD} = "$dir/swap.so";
        open my $child, '-|', $^X, (map { "-I$_" } @INC), "$dir/open.pl", $class, $path, $replacement
            or die $!;
        my $out = do { local $/; <$child> };
        close $child;
        is $?, 0, "$class $case: constructor completed";
        is $out, "replacement survives\n", 'unlink leaves the channel that replaced the mapped file';
    }
}

done_testing;
