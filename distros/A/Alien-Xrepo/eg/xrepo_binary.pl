use v5.40;
use blib;
use Alien::Xrepo;
use Path::Tiny;
use Config;

# xrepo does not only build shared libraries - it also ships ready-to-run BINARIES (ninja, cmake, meson, python, node, go, rust, ...). `install` returns the package installdir, and `bin_dir` tells you where the executables live.
my $repo  = Alien::Xrepo->new();
my $ninja = $repo->install('ninja') or die 'ninja install failed';
my @bins  = $ninja->bin_dir;
say 'ninja installation root: ' . $ninja->installdir;

# Option A: run a single binary straight from bin_dir
my ($ninja_exe) = map { path($_)->child( $^O eq 'MSWin32' ? 'ninja.exe' : 'ninja' ) } @bins;
system $ninja_exe, '--version';

# Option B: put bin_dir first on PATH, so a plain 'ninja' resolves (and every child of this process inherits it)
local $ENV{PATH} = join $Config{path_sep}, ( @bins, $ENV{PATH} );
system 'ninja', '--version';
