use strict;
use warnings;
use Test::More;
use Config;
use Errno qw(ENOSPC EOPNOTSUPP EINVAL);
use File::Temp qw(tempdir);
use ExtUtils::CBuilder;

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $builder = ExtUtils::CBuilder->new(quiet => 1);
plan skip_all => 'C compiler required' unless $builder->have_compiler;
my $dir = tempdir(CLEANUP => 1);
open my $source, '>', "$dir/reserve.c" or die $!;
print {$source} <<'C';
#include <stdlib.h>
#include <fcntl.h>
int posix_fallocate(int fd, off_t off, off_t len) {
    (void)fd; (void)off; (void)len;
    return atoi(getenv("RSV_TEST_RESERVE_ERROR"));
}
C
close $source;
my $obj = $builder->compile(source => "$dir/reserve.c");
my $lib = $builder->link(objects => $obj, module_name => 'reserve');
local $ENV{LD_PRELOAD} = join ':', grep { defined && length } $ENV{LD_PRELOAD}, $lib;
local $ENV{DATA_RESERVOIR_SHARED_SPARSE} = 0;

for my $ctor (qw(new new_weighted new_memfd new_weighted_memfd)) {
    for my $error (0, ENOSPC, EOPNOTSUPP, EINVAL) {
        local $ENV{RSV_TEST_RESERVE_ERROR} = $error;
        my $path = "$dir/$ctor-$error.rsv";
        open my $child, '-|', $Config{perlpath}, '-Mblib', '-MData::Reservoir::Shared', '-e', q{
            my ($ctor, $path) = @ARGV;
            my $r = eval { Data::Reservoir::Shared->$ctor($path, 10, 32) };
            print $r ? "created\n" : "refused: $@";
        }, $ctor, $path or die $!;
        my $out = do { local $/; <$child> };
        close $child;
        is $?, 0, "$ctor error $error: no signal or child failure";
        like $out, $error ? qr/^refused: .*cannot reserve/ : qr/^created/,
            "$ctor error $error: reservation result is honored";
        is -s $path, 0, "$ctor error $error: failed file create rolled back"
            if $error && $ctor !~ /memfd/;
    }
}

done_testing;
