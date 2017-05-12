use strict;
use Test::More tests => 2;

use Apache::RSS;
use Apache::Constants qw(:common);

{
    no strict 'refs';
    *Apache::Constants::DECLINED = sub {-1};
    *Apache::Constants::FORBIDDEN = sub {403};
    *Apache::Constants::OK = sub {0};
    *Apache::Constants::OPT_INDEXES = sub {1};
}

{
    package Apache::ModuleConfig;
    sub get{
	Apache::RSS::DIR_CREATE('MockConf');
    }
}

my $log;
{
    package Apache::RSS::TestRequest;
    sub new { bless {}, shift; }
    sub filename { return './t/test_dir/'; }
    sub args{ return index => 'rss'; }
    sub allow_options{ 0 }
    sub log_reason{ shift; $log = shift; }
}

is(Apache::RSS->handler(Apache::RSS::TestRequest->new), FORBIDDEN);
like($log, qr/^Options Indexes/);
