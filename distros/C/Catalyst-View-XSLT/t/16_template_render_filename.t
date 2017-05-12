use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $view = 'XML::LibXSLT';

my $response;
ok(($response = request("/test_template_render_filename?view=$view&template=testRenderFilename.xsl"))->is_success, 'request ok');
is($response->content, '<dummy-root>' . TestApp->config->{default_message} . "</dummy-root>\n", 'message ok');

my $message = scalar localtime;
my $xml = "<dummy-root>$message</dummy-root>\n";
ok(($response = request("/test_template_render_filename?view=$view&message=$message&template=testRenderFilename.xsl"))->is_success, 'request with message ok');
is($response->content, $xml, 'message ok');

