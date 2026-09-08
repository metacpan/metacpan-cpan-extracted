use v5.40;
use FindBin qw[$Bin];
use Path::Tiny;
use Alien::Xrepo::Build;

# Drive the Alien::Xrepo::Build pipeline (configure -> probe -> install ->
# gather -> export) from the xrepo.json recipe in this directory. The snapshot
# lands in the dist's share dir so Alien::lsquic can also resolve hermetically
# (no xrepo subprocess) once built; otherwise it resolves dynamically.
my $dist     = 'Alien-lsquic';
my $snapshot = path($Bin)->child( 'blib', 'lib', 'auto', 'share', 'dist', $dist, 'xrepo-snapshot.json' );

Alien::Xrepo::Build->new( recipe => $Bin, snapshot => $snapshot )->run;