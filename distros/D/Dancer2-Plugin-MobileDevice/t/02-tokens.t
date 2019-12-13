use 5.008001;
use strict;
use warnings;

use Test::More import => ['!pass'];
use Test::NoWarnings;
use Plack::Test;
use HTTP::Request::Common;

plan tests => 3;

{
    package TestApp;
    use Dancer2;
    use File::Spec;
    use Dancer2::Plugin::MobileDevice;

    set template => 'simple';   # default is 'tiny'
    set views => File::Spec->catfile('t', 'views');

    get '/' => sub {
        template 'index', {}, {layout => undef};
    };
}


my $dut = Plack::Test->create(TestApp->to_app);
my $resp;

$resp = $dut->request( GET '/', 'User-Agent' => 'Android');
is $resp->content,
    "is_mobile_device: 1\n",
    "token is_mobile_device is present and valid for Android";

$resp = $dut->request( GET '/', 'User-Agent' => 'Mozilla');
is $resp->content,
    "is_mobile_device: 0\n",
    "token is_mobile_device is present and valid for Mozilla";

