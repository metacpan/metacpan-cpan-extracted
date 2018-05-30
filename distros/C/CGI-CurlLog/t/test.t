use strict;
use warnings;
use lib "lib";
use Test::More;

BEGIN {
    $ENV{"GATEWAY_INTERFACE"} = "CGI/1.1";
    $ENV{"HTTP_HOST"} = "example.org";
    $ENV{"REQUEST_URI"} = "/foo.php?a=b&c=d&e=f";
    $ENV{"REMOTE_ADDR"} = "1.2.3.4";

    require CGI::CurlLog;
    CGI::CurlLog->import(file => "curl.log", response => 0);
}

my $content = `cat curl.log`;

my $test = $content =~ m{^#.* request from 1.2.3.4\n}m &&
           $content =~ m{^curl "http://example.org/foo.php\?a=b&c=d&e=f" -k\n}m;
ok $test, "log lines are as expected";

done_testing();

END {
    unlink "curl.log";
}
