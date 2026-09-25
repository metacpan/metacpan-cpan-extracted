use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

# A create whose mmap fails, as a channel over about 2.5 GiB does on a 32-bit
# perl, here under RLIMIT_AS; sparse, so nothing is written to disk.

plan skip_all => 'Linux only' unless $^O eq 'linux';

my $root = dirname(dirname(abs_path(__FILE__)));
my $dir  = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/child.pl" or die $!;
print {$fh} <<'P';
use strict; use warnings;
use Data::ReqRep::Shared; use Data::ReqRep::Shared::Int;
my ($path, $class, @args) = @ARGV;
my $pkg = $class eq q{Int} ? q{Data::ReqRep::Shared::Int} : q{Data::ReqRep::Shared};
print eval { $pkg->new($path, @args); 1 } ? "created\n" : "refused: $@";
P
close $fh;

for my $case (['Str', 16, 1024, 1 << 20], ['Int', 16, 1 << 23]) {
    my ($class, @args) = @$case;
    my $path = "$dir/$class.shm";
    my $out = qx{DATA_REQREP_SHARED_SPARSE=1 sh -c 'ulimit -v 300000; exec "\$@"' sh $^X -I$root/blib/lib -I$root/blib/arch $dir/child.pl $path $class @args 2>&1};
    like $out, qr/^refused: .*mmap\(\Q$path\E\): Cannot allocate memory/, "$class: a segment the process cannot map is refused";
    is -s $path, 0, '  and the file it created is left empty';
    $out = qx{$^X -I$root/blib/lib -I$root/blib/arch $dir/child.pl $path $class 16 4 @{[ $class eq 'Str' ? 64 : () ]} 2>&1};
    like $out, qr/^created/, '  so a later create succeeds';
}

done_testing;
