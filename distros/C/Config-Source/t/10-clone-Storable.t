use 5.14.0;
use warnings FATAL => 'all';

use FindBin;
use File::Spec;

use Test::More;
use Test::Exception;

use lib $FindBin::Bin;
use CloneTest;

# storable is default
use Config::Source;

my $config = Config::Source->new;

CloneTest->test( $config );

done_testing();

1;
