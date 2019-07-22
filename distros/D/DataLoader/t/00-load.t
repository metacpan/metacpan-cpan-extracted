use v5.14;
use warnings;
use Test::More tests => 3;
use FindBin ();
use lib "$FindBin::Bin/lib";

BEGIN {
    use_ok('DataLoader');
    use_ok('DataLoader::Error');
    use_ok('DataLoader::Test');
}
