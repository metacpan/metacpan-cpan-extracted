#! perl

use strict;
use warnings;

use File::Spec;
use Data::Dumper;

use Dancer qw/:syntax/;

set template => 'template_flute';

set views => 't/views';
set log => 'debug';

get '/' => sub {
    template product => {};
};

use Test::More tests => 16, import => ['!pass'];

use Dancer::Test;

response_content_like [GET => '/'], qr/product-gallery/,
  "content looks good for /";
my $logs = read_logs;

ok (@$logs == 4);
diag to_dumper($logs);
foreach my $log (@$logs) {
    is $log->{level}, "debug", "Debug found";
    like $log->{message}, qr/Found dangling element/, "log looks good";
}


set environment => 'production';

response_content_like [GET => '/'], qr/product-gallery/,
  "content looks good for /";

$logs = read_logs;

is_deeply $logs, [], "No logs found in production";

set environment => 'development';

response_content_like [GET => '/'], qr/product-gallery/,
  "content looks good for /";
$logs = read_logs;

ok ((@$logs == 4), "Logs found in development");

set engines => {
                template_flute => { disable_check_dangling => 1 },
               };

set template => 'template_flute';

response_content_like [GET => '/'], qr/product-gallery/,
  "content looks good for /";

$logs = read_logs;

is_deeply $logs, [], "No logs found in development with disable_check_dangling";
