use Test::Most;

use FindBin '$Bin';
use lib "$Bin/../lib";
use Dancer2;
use_ok 'Dancer2::Plugin::OpenAPIRoutes'; 

done_testing()