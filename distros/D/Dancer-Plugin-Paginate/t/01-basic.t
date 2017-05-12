use strict;
use warnings;

use Test::More import => ['!pass'];
use t::lib::TestApp;
use Dancer ':syntax';

my $dancer_version;
BEGIN {
    $dancer_version = (exists &dancer_version) ? int(dancer_version()) : 1;
    require Dancer::Test;
    if ($dancer_version == 1) {
        Dancer::Test->import();
    } else {
        Dancer::Test->import('t::lib::TestApp');
    }
}

diag sprintf "Testing Paginate version %s under Dancer %s",
    $Dancer::Plugin::Paginate::VERSION,
    $Dancer::VERSION;

response_content_is [GET => '/'], "Index ok", "Does nothing on requests without range";


my $headers = [
    'X-Requested-With' => 'XMLHttpRequest',
    'Range' => '0-24',
    'Range-Unit' => 'Item'
];
my $basic_response = dancer_response(GET => '/page', { headers => $headers } );
is $basic_response->status, 206, "Status changed to 206";
is $basic_response->header('Content-Range'), '0-24/*', "Content-Range is defaulted to *";
is $basic_response->header('Range-Unit'), 'Item', "Range-Unit is inputted 'Item'";
is_deeply from_json($basic_response->content), { start => 0, end => 24, unit => 'Item' }, "Content is accurate";

my $total_response = dancer_response(GET => '/total', { headers => $headers });
is $total_response->header('Content-Range'), '0-24/100', "Content-Range's total is set to 100";

my $range_response = dancer_response(GET => '/range', { headers => $headers });
is $range_response->header('Content-Range'), '0-100/*', "Content-Range was set to 0-100 properly";

my $params = {
    'Start' => 0,
    'End' => 24,
    'Range-Unit' => 'Item'
};

my $params_response = dancer_response(GET => '/page', { params => $params, headers => [ 'X-Requested-With' => 'XMLHttpRequest' ] });
is $params_response->header('Content-Range'), '0-24/*', "Content-Range is returned from parameters";
is $params_response->header('Range-Unit'), 'Item', "Range-Unit is returned from parameters";

done_testing();

