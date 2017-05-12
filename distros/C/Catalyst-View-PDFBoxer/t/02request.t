use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response;
ok(($response = request("/test?template=test.tt"))->is_success, 'request ok');

is( ($response->content_type)[0], 'application/pdf', 'content type ok' );
is( ($response->content_type)[1], 'charset=utf-8', 'charset ok' );

cmp_ok( $response->content, '=~', '^%PDF-', 'pdf sig in content' );


#open(my $fh, '>', '02request.pdf') or die "02request.pdf: $!";
#print $fh $response->content;
#close($fh);

