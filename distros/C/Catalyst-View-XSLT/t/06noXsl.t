
#
# Test without give a xslt template name
# It must be created by the current action name plus 
# the configured TEMPLATE_EXTENSION
#

use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use_ok('Catalyst::Test', 'TestApp');

my $view = 'XML::LibXSLT';

my $response;
ok(($response = request("/testNoXSLT?view=$view"))->is_success, 'request ok');
is($response->content, TestApp->config->{default_message}, 'message ok');

my $message = scalar localtime;
ok(($response = request("/testNoXSLT?view=$view&message=$message"))->is_success, 'request with message ok');
is($response->content,  $message, 'message ok');
