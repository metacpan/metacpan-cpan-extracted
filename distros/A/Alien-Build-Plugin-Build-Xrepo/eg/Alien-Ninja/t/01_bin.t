use v5.40;
use blib;
use Test2::V0;
use Capture::Tiny qw[capture];
use Alien::Ninja;

# The plugin's gather_share hooks bin_dir; the exe() helper finds the binary inside it. Skip on a
# cold checkout where nothing is installed yet.
my $ninja = Alien::Ninja->new;
my $exe   = $ninja->exe;
SKIP: {
    skip_all 'ninja not resolved yet; run `perl Makefile.PL && make` first' unless $exe;
    ok( -e $exe, 'ninja executable located: ' . $exe );
    my ( $out, undef, $err ) = capture { system $exe, '--version'; };
    like "$out$err", qr[\d+\.\d+\.\d+], 'ninja --version prints a semver';
}
#
done_testing;
