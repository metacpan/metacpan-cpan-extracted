use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

# Hack to support Catalyst v5.90080+ (JNAP)
if(TestApp->can('encoding') and (my $enc = TestApp->encoding) and TestApp->can('clear_encoding')) {
  is(request("/test_alt_content_type")->header('Content-Type'), "text/plain; charset=${\$enc->mime_name}", "Plain text with ${\$enc->mime_name}");
} else {
  is(request("/test_alt_content_type")->header('Content-Type'), 'text/plain', 'Plain Text');
}
done_testing;
