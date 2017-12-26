use strict;
use warnings;

use Test::More import => ['!pass'];
use Test::NoWarnings;

my @mobile_devices = qw(iPhone iPod iPad Android BlackBerry PalmOS);

plan tests => @mobile_devices + 3;

{
    use Dancer;
    use Dancer::Plugin::MobileDevice;

    get '/' => sub {
        return is_mobile_device;
    };
}

use Dancer::Test;

for my $md (@mobile_devices) {
    $ENV{HTTP_USER_AGENT} = $md;
    my $resp = dancer_response GET => '/'; 

    my $content = $resp->{content};

    is $content => 1, "agent $md is a mobile device";
}


subtest Mozilla => sub {

    $ENV{HTTP_USER_AGENT} = 'Mozilla';
    my $resp = dancer_response GET => '/'; 

    my $content = $resp->{content};

    is $content => 0, "Mozilla is not a mobile device";
};

subtest 'no user agent at all' => sub {

    delete $ENV{HTTP_USER_AGENT};
    my $resp = dancer_response GET => '/'; 

    my $content = $resp->{content};

    is $content => 0, "nothing is not a mobile device";
};
