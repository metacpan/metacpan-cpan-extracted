use strict;
use warnings;
use Test::More;
use Test::Requires {
    "Twiggy::Server" => "0",
};
use Twiggy::Server;
use FindBin;
use lib ($FindBin::RealBin);
use testlib::PSGI qw(run_tests);

run_tests sub {
    my ($port, $app) = @_;
    my $twiggy = Twiggy::Server->new(
        host => "127.0.0.1",
        port => $port
    );
    $twiggy->register_service($app);
    return $twiggy;
};

done_testing;

