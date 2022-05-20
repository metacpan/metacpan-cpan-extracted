use warnings;
use strict;

use Hook::Output::Tiny;
use Mock::Sub;
use Addr::MyIP;
use Test::More;

if (! $ENV{DEV_TESTING} || $ENV{RELEASE_TESTING}) {
    note "DEV_TESTING env var not set or RELEASE_TESTING is, running mock tests";

    my $m = Mock::Sub->new;
    my $get_sub = $m->mock('HTTP::Tiny::get');

    # Valid return
    {
        $get_sub->return_value({status => 200, content => 'fe80::14ab:e67f:2094:e644'});
        my $ip6 = myip6();

        is $get_sub->called_count, 1, "HTTP client get called ok (mocked)";
        is $ip6, 'fe80::14ab:e67f:2094:e644', "myip6() returns ok";
    }

    # non-200 return
    {
        $get_sub->reset;

        $get_sub->return_value({status => 403, content => 'Unauthorized'});
        my $h = Hook::Output::Tiny->new;

        $h->hook;
        my $ip = myip6();
        $h->unhook;

        my @stderr = $h->stderr;

        like
            $stderr[0],
            qr/Unauthorized/,
            "on unsuccessful API call, display the error";

        is $get_sub->called_count, 1, "HTTP client get called ok (mocked)";
        is $ip, '', "myip() returns empty string on API fail ok";
    }
}

if ($ENV{DEV_TESTING} || $ENV{RELEASE_TESTING}) {
    # Valid return
    {
        my $ip = myip6();
        like
            $ip,
            qr/(:|^$)/,
            "myip6() returns ok";
    }
}

done_testing();