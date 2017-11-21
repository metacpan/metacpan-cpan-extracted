use strict; use warnings;

use FindBin qw/ $RealBin /;
use lib "$RealBin/../lib";

use Data::Dumper;
$Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1;

use Dancer2;
use Dancer2::Logger::LogAny;

get '/' => sub {
    debug Dumper config;
    warning "warning: Returning from /";
    return "Hello, world";  
};

dance;

__END__
