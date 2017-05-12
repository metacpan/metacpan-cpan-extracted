use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my $config = Apache::Test::config();
my $path = Apache::TestRequest::module2path('TestDirective::perlrequire');

my @vhosts = qw(default vhost1 vhost2);

plan tests => 2 * scalar @vhosts;

for my $name (@vhosts) {

    Apache::TestRequest::module($name);
    my $hostport = Apache::TestRequest::hostport($config) || '';
    t_debug("connecting to $hostport");
    my $location = "http://$hostport/vmonitor";
    my $str = GET_BODY_ASSERT $location;

    ok $str;

    ok t_cmp $str, qr/Apache::VMonitor/, $hostport;
}

