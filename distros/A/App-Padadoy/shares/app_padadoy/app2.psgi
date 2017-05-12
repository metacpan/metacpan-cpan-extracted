use File::Basename qw(dirname);
use File::Spec::Functions;
use lib catdir(dirname($0), 'lib');

use YOUR_MODULE;

# TODO: if YOUR_MODULE derives from Dancer:
## use Dancer;
## dance;

# otherwise:
my $app = YOUR_MODULE->new;

$app;
