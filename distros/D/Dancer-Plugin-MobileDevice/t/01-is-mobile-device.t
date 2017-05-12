use strict;
use warnings;

use Test::More import => ['!pass'];

my @mobile_devices = qw(iPhone iPod iPad Android BlackBerry PalmOS);

plan tests => scalar(@mobile_devices) + 1;

{
    use Dancer;
    use Dancer::Plugin::MobileDevice;

    get '/' => sub {
        return is_mobile_device;
    };
}

use Dancer::Test;

for my $md (@mobile_devices) {
    $ENV{HTTP_USER_AGENT} = $md; # for Dancer 1.x
    my $resp = dancer_response GET => '/', 
        undef, 
        { HTTP_USER_AGENT => $md };  # for Dancer 2.x

    my $content = $resp->{content};

    is $content => 1, "agent $md is a mobile device";
}

$ENV{HTTP_USER_AGENT} = 'Mozilla';
    my $resp = dancer_response GET => '/', 
        undef, 
        { HTTP_USER_AGENT => 'Mozilla' };  # for Dancer 2.x

my $content = $resp->{content};

is $content => 0, "Mozilla is not a mobile device";

