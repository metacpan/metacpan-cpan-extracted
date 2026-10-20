use v5.40;
use Exotic::Ninja;

# A binary-tool consumer: resolve the dist and put its bin dir on PATH so the
# shipped tool resolves. prepend_to_path returns the directories it prepended.
# Runtime resolution is hermetic (snapshot) -- no xrepo subprocess.
my $ninja = Exotic::Ninja->new;
my @bin   = $ninja->prepend_to_path;
die 'Could not find ninja installation' unless @bin;
my $exe     = 'ninja' . ( $^O eq 'MSWin32' ? '.exe' : '' );
my $version = `$exe --version`;
die "failed to run $exe: $!" unless defined $version;
say 'ninja:  ' . join( ', ', @bin );
say 'version: ' . ( split /\r?\n/, $version )[0];
