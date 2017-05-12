use strict;
use warnings;

use Test::More import => ['!pass'];

plan tests => 2;

{
    use Dancer;
    use File::Spec;
    use Dancer::Plugin::MobileDevice;

    set views => File::Spec->catfile('t', 'views');

    get '/' => sub {
        template 'index', {}, {layout => undef};
    };
}

use Dancer::Test;

$ENV{HTTP_USER_AGENT} = 'Android';
is dancer_response( GET => '/', undef, { 
        HTTP_USER_AGENT => 'Android'
    })->{content},
    "is_mobile_device: 1\n", 
    "token is_mobile_device is present and valid for Android";

$ENV{HTTP_USER_AGENT} = 'Mozilla';
is dancer_response( GET => '/', undef, { 
        HTTP_USER_AGENT => 'Mozilla' 
    })->{content},
    "is_mobile_device: 0\n", 
    "token is_mobile_device is present and valid for Mozilla";

