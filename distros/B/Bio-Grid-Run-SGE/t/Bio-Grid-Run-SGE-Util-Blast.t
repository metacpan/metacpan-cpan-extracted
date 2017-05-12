use warnings;
use Data::Dumper;
use Test::More qw/no_plan/;

BEGIN { use_ok("Bio::Grid::Run::SGE::Util::Blast"); }

my $d;
sub TEST { $d = $_[0]; }

#TESTS
