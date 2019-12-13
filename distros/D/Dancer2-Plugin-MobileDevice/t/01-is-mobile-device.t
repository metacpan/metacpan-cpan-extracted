use 5.008001;
use strict;
use warnings;

use Test::More import => ['!pass'];
use Test::NoWarnings;
use Plack::Test;
use HTTP::Request::Common;

my @mobile_devices = qw(iPhone iPod iPad Android BlackBerry PalmOS);

plan tests => @mobile_devices + 3;

{
    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::MobileDevice;

    get '/' => sub {
        return is_mobile_device;
    };
}

my $dut = Plack::Test->create(TestApp->to_app);

for my $md (@mobile_devices) {
    my $resp = $dut->request(GET '/', 'User-Agent' => $md);
    is $resp->content, 1, "agent $md is a mobile device";
}


subtest Mozilla => sub {
    my $resp = $dut->request(GET '/', 'User-Agent' => 'Mozilla');
    is $resp->content, 0, "Mozilla is not a mobile device";
};


subtest 'no user agent at all' => sub {
    my $req = GET('/');
    $req->headers->remove_header('User-Agent'); # just in case
    my $resp = $dut->request($req);
    is $resp->content, 0, "nothing is not a mobile device";
};
