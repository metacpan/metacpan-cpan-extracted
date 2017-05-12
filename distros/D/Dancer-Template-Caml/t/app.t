use strict;
use warnings;

use Test::More import => ["!pass"];

use Dancer ':syntax';
use Dancer::Test;

plan tests => 3;

setting views    => 't';
setting template => 'caml';

ok( get '/' => sub {
        template 'index', {name => 'vti'};
    }
);

my $logs = read_logs;

route_exists [GET => '/'];
response_content_like([GET => '/'], qr/vti/);
