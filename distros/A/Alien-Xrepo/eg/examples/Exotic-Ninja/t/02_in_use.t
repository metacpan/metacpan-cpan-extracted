use v5.40;
use blib;
use Test2::V0;
use Path::Tiny;
use Exotic::Ninja;
#
my $ninja = Exotic::Ninja->new;

# The package must actually be installed (a build-served snapshot or a store
# hit); otherwise there is nothing at all to exercise.
SKIP: {
    my $info = $ninja->package_info;
    skip 'ninja not installed; run the build first' => 1 unless $info;
    ok defined $ninja->version, 'resolved package version is recorded';
}

# Run the binary we installed and read its version off the command line.
SKIP: {
    my @bin = $ninja->bin_dir;
    skip 'ninja not installed; run the build first' => 2 unless @bin;
    my $exe = path( $bin[0] )->child( $^O eq 'MSWin32' ? 'ninja.exe' : 'ninja' );
    ok $exe->is_file, 'ninja executable is a file';
    my $out = qx{"$exe" --version 2>&1};
    like $out, qr{^\s*\d+\.\d+(?:\.\d+)?}, 'ninja --version reports a version' or diag $out;
}
#
done_testing;
