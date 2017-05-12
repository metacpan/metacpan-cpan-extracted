use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest;

my $module = "TestDebugFilter::snoop";
my $path = Apache::TestRequest::module2path($module);
Apache::TestRequest::module($module);
my $config = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config);
t_debug("connecting to $hostport");

plan tests => 1;

my $data = "ok 1\n";
print POST_BODY_ASSERT $path, content => $data;

