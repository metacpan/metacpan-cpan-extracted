use v5.40;
use blib;
use Alien::Xrepo;
use Path::Tiny;
#
my $repo    = Alien::Xrepo->new();
my $library = 'libsdl3_ttf';

# Generate graph
say "Fetching dependency graph for $library...";
my $dot = $repo->info( 'libsdl3_ttf', depgraph => 1, format => 'dot' );

# Write it to disk
path('deps.dot')->spew($dot);
say 'Give "deps.dot" to Graphvis! Something like `dot -Tsvg deps.dot -o diagram.svg`';
