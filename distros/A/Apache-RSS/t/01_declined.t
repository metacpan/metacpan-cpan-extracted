use strict;
use Test::More tests => 1;

BEGIN {
    $INC{'Apache::ModuleConfig'} = '/dev/null';
}
use Apache::RSS;
use Apache::Constants qw(:common);
use Apache::ModuleConfig;

{
    *Apache::Constants::DECLINED = sub {-1};
    *Apache::Constants::FORBIDDEN = sub {403};
    *Apache::Constants::OK = sub {0};
}

{
    package Apache::ModuleConfig;
    sub get{
	Apache::RSS::DIR_CREATE('MockConf');
    }
}

{
    package Apache::RSS::TestRequest;
    sub new { bless {}, shift; }
    sub filename { return ''; }
}

is(Apache::RSS->handler(Apache::RSS::TestRequest->new), DECLINED);
