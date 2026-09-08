use v5.40;
use blib;
use Alien::Xrepo;
use Path::Tiny;

# Alien::Xrepo feature tour. Each section is independent, so comment out the parts you do not need. Optional flags:
#   --third-party  install from vcpkg/conan/brew (needs the manager on PATH)
#   --clean        run xrepo clean (it also removes installed packages)
my $repo     = Alien::Xrepo->new();
my $show_3p  = grep {/^--third-party$/} @ARGV;
my $do_clean = grep {/^--clean$/} @ARGV;
my $store    = Path::Tiny->tempdir( CLEANUP => 1 );
my $exe_name = $^O eq 'MSWin32' ? '.exe' : '';

# Repositories and search
say "# Repositories";
say for $repo->list_repo;
say "\n# Search 'sqlite' (xmake-repo)";
say for $repo->search('sqlite');

# Install + fetch (the core workflow)
say "\n# Install libpng (shared, default config)";
my $libpng = $repo->install('libpng') or die 'libpng install failed';
say '  libpath:   ' . $libpng->libpath;
say '  version:   ' . $libpng->version;
say '  license:   ' . $libpng->license;
say '  header:    ' . $libpng->find_header('png.h');
say "\n# Fetch build flags (handy for MakeMaker / plain cc)";
say '  cflags:  ' . $repo->fetch( 'libpng', undef, cflags  => 1 );
say '  ldflags: ' . $repo->fetch( 'libpng', undef, ldflags => 1 );

# Dependency graph (render with Graphviz:  dot -Tpng dep.dot -o dep.png)
say "\n# Dependency graph for libpng (Graphviz DOT)";
my $dot     = $repo->info( 'libpng', depgraph => 1, format => 'dot' );
my $dotfile = path($store)->child('libpng.dep.dot');
$dotfile->spew($dot);
say $dot;
say "\n  (graph also saved to $dotfile; render: dot -Tpng \"$dotfile\" -o dep.png)";

# Isolated, reproducible package store
say "\n# Install pcre2 into a project-local store";
my $pcre2 = $repo->install( 'pcre2', undef, installdir => $store ) or die 'pcre2 install failed';
say '  store:    ' . $store;
say '  libpath:  ' . $pcre2->libpath;
say '  bin:      ' . join ', ', $pcre2->bin_dir if $pcre2->bin_dir;
say "\n# What lives in the isolated store?";
say for $repo->scan( 'pcre2', installdir => $store );
say "\n# Fetch straight from that store (no install)";
( my $p = $pcre2->libpath ) =~ s{\\}{/}g;
( my $s = "$store" )        =~ s{\\}{/}g;
say '  kept under store? ' . ( index( $p, $s ) == 0 ? 'yes' : 'no' );

# Tools: install and run binaries (not just libraries)
say "\n# Install a build tool (ninja)";
my $ninja = $repo->install('ninja') or die 'ninja install failed';
say '  installdir: ' . $ninja->installdir;
say '  bin:        ' . join ', ', $ninja->bin_dir;
my ($nbin) = grep { -e $_ } map { path($_)->child("ninja$exe_name") } $ninja->bin_dir;
say '  ninja version: ' . ( `"$nbin" --version` // '' );
say "\n# Install the python interpreter (a binary package)";
my $py = $repo->install('python') or die 'python install failed';
say '  installdir: ' . $py->installdir;
my ($pbin) = grep { -e $_ } map { path($_)->child("python$exe_name") } $py->bin_dir;
say '  python version: ' . ( `"$pbin" --version` // '' );

# Third-party package managers: vcpkg / conan / brew / ...
# Namespace the package spec; decode them like any other package. Requires the underlying manager to be installed and on PATH.
if ($show_3p) {
    say "\n# Search third-party namespaces";
    say for $repo->search('vcpkg::pcre');
    say "\n# Install from third-party managers";
    $repo->install( 'vcpkg::zlib',        undef );
    $repo->install( 'conan::zlib/1.2.11', undef ) if $^O ne 'MSWin32';
    $repo->install( 'brew::zlib',         undef ) if $^O ne 'MSWin32';
}
else {
    say '';
    say '# Enabled with  --third-party  (requires vcpkg/conan/brew on PATH):';
    say '#   $repo->install("vcpkg::zlib");';
    say '#   $repo->install("conan::zlib/1.2.11");';
    say '#   $repo->install("brew::zlib");';
    say '#   $repo->search("vcpkg::pcre");';
}

# Offline distribution: download / import / export
my $dl = Path::Tiny->tempdir( CLEANUP => 1 );
$repo->download( 'pcre2', undef, outputdir => $dl, shallow => 1 );
say "\n# Downloaded sources:";
say '  - ' . $_ for $dl->children;

# Environment
say "\n# Package environment (--show)";
$repo->env( undef, show => 1, bind => 'zlib' );
say "";
say "# To enter a shell with the package env configured:";
say "#   \$repo->env( undef, bind => 'zlib' );";

# Cleanup (uninstall + optional xrepo clean)
say "\n# Uninstall pcre2 from the isolated store";
$repo->uninstall( 'pcre2', installdir => $store );
if ($do_clean) {
    say "\n# xrepo clean removes installed packages and caches (opt-in via --clean)";
    $repo->clean();
}
