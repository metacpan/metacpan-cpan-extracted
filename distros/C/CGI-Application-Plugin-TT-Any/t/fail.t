use strict;
use warnings;

package fail_test;

BEGIN {
    chdir '..' if -d '../t';
    use lib './lib';
}

use Test::Most;
use Test::Fatal;

BEGIN { require_ok('CGI::Application::Plugin::TT::Any') };

like(
    exception { CGI::Application::Plugin::TT::Any->import; },
    qr{CGI::Application::Plugin::TT needs to be loaded first},
    "can't load before CAP::TT",
);

done_testing;
