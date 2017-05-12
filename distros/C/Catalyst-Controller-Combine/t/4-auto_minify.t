use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

#
# sanity check first -- controller
#
my $controller = TestApp->controller('JsMin');
is( ref($controller), 'TestApp::Controller::JsMin', 'Controller is OK');
can_ok($controller => 'minify');

#
# get a context object
#
like( get('/jsmin/js1.js'),
      qr{\A \# \s+ /\* \s+ javascript \s+ 1 \s+ \*/ \s+ \# \s* \z}xms,
      'minified JavaScript looks OK' );

#
# now see if the failing controller really fails
# well it does not fail, it does not minify
#
my $failing_controller = TestApp->controller('JsFail');
is( ref($failing_controller), 'TestApp::Controller::JsFail', 'Controller is OK');
ok(!UNIVERSAL::can($failing_controller,'minify'), 'failing controller has no "minify" routine');

like( get('/jsfail/js1.js'),
      qr{\A \s* /\* \s+ javascript \s+ 1 \s+ \*/ \s* \z}xms,
      'want-minified JavaScript is not minified' );

done_testing;
