use strict;
use warnings;

use Test2::V0;

ok(1, 'test harness works');

sub module_loads {
    my ($module) = @_;
    (my $file = "$module.pm") =~ s{::}{/}g;

    my $ok = eval {
        require $file;
        1;
    };

    ok($ok, "loads $module")
      or diag($@ || "Unknown error loading $module");
}

module_loads('EasyDNS::DDNS');
module_loads('EasyDNS::DDNS::Config');
module_loads('EasyDNS::DDNS::HTTP');
module_loads('EasyDNS::DDNS::State');
module_loads('EasyDNS::DDNS::Util');

done_testing;

