use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

#
# sanity check first -- controller
#
my $controller = TestApp->controller('Js');
is( ref($controller), 'TestApp::Controller::Js', 'Controller is OK');

#
# get a context object
#
my ($res, $c) = ctx_request('/call_uri');
is( ref($c), 'TestApp', 'context is OK' );

#
# test the 'uri_for' function
#
like( $c->uri_for($controller->action_for('default'), 'js1.js'), 
      qr{\A http://\w+/js/js1\.js \? m=\d+ \z}xms, 
      'uri #1 looks good');
like( $c->uri_for($controller->action_for('default'), 'js1'), 
      qr{\A http://\w+/js/js1\.js \? m=\d+ \z}xms, 
      'uri #2 looks good');
like( $c->uri_for($controller->action_for('default'), 'js2.js'), 
      qr{\A http://\w+/js/js2\.js \? m=\d+ \z}xms, 
      'uri #3 looks good');
like( $c->uri_for($controller->action_for('default'), 'js1', 'js2.js'), 
      qr{\A http://\w+/js/js2\.js \? m=\d+ \z}xms, 
      'uri #4 looks good');
like( $c->uri_for($controller->action_for('default'), 'js2', 'js1.js'), 
      qr{\A http://\w+/js/js2\.js \? m=\d+ \z}xms, 
      'uri #5 looks good');
like( $c->uri_for($controller->action_for('default'), 'js2.js', 'js1.js'), 
      qr{\A http://\w+/js/js2\.js \? m=\d+ \z}xms, 
      'uri #6 looks good');

#
# test getting javascript contents
#

# single file - w/ ext
like( get('/js/js1.js'),
      qr{\A /\* \s+ javascript \s+ 1 \s+ \*/ \s* \z}xms,
      'JavaScript #1 looks OK' );

# single file - w/o ext
like( get('/js/js1'),
      qr{\A /\* \s+ javascript \s+ 1 \s+ \*/ \s* \z}xms,
      'JavaScript #2 looks OK' );
      
# not existing + single file - w/o ext
like( get('/js/xyz/js1'),
      qr{\A /\* \s+ javascript \s+ 1 \s+ \*/ \s* \z}xms,
      'JavaScript #3 looks OK' );

# multiple files, last w/ ext
like( get('/js/js1/js2.js'),
      qr{\A /\* \s+ javascript \s+ 1 \s+ \*/ \s* /\* \s+ javascript \s+ 2 \s+ \*/ \s+ \z}xms,
      'JavaScript #4 looks OK' );
      
# multiple files, first w/ ext
like( get('/js/js1.js/js2'),
      qr{\A /\* \s+ javascript \s+ 1 \s+ \*/ \s* /\* \s+ javascript \s+ 2 \s+ \*/ \s+ \z}xms,
      'JavaScript #5 looks OK' );

# multiple files, all w/ ext
like( get('/js/js1.js/js2.js'),
      qr{\A /\* \s+ javascript \s+ 1 \s+ \*/ \s* /\* \s+ javascript \s+ 2 \s+ \*/ \s+ \z}xms,
      'JavaScript #6 looks OK' );

# one file that depends on another, w/ extension
like( get('/js/js2.js'),
      qr{\A /\* \s+ javascript \s+ 1 \s+ \*/ \s* /\* \s+ javascript \s+ 2 \s+ \*/ \s+ \z}xms,
      'JavaScript #7 looks OK' );

# one file that depends on another, w/o extension
like( get('/js/js2'),
      qr{\A /\* \s+ javascript \s+ 1 \s+ \*/ \s* /\* \s+ javascript \s+ 2 \s+ \*/ \s+ \z}xms,
      'JavaScript #8 looks OK' );

#
# fake in a 'minify' routine that removes spaces
#
*{TestApp::Controller::Js::minify} = sub {
    my $text = shift;
    $text =~ s{\s+}{}xmsg;
    return $text;
};

#
# test minification -- CAUTION: a newline may get added at the end...
#
like( get('/js/js1.js'),
      qr{\A /\* javascript1 \*/ \s* \z}xms,
      'minified JavaScript looks OK' );

# suppress warning
my $dummy = *{TestApp::Controller::Js::minify};

done_testing;
