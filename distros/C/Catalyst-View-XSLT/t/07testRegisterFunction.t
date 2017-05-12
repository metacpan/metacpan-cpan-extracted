use strict;
use warnings;
use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $view = 'XML::LibXSLT';

my $response;
ok(($response = request("/testRegisterFunction?view=$view&template=testRegisterFunction.xsl"))->is_success, 'request ok');
is($response->content, TestApp->config->{default_message}, 'message ok');

