package MyApp;

use strict;
use warnings;

use Test::More tests => 2;

use Dancer2;
use Dancer2::Test;

set engines => {
      template => {
        Haml => {
          cache => 0,
        },
      },
};
set template => 'Haml';

get '/' => sub { template 'myview', {}, {layout => undef} };

response_content_is '/' => '<h1>hello world</h1>
';

set layout => 'main';
set charset => 'utf8';
set appname => 'hello world';

get '/test' => sub { template 'myview' };

response_content_is '/test' => <<'EOF';
<!DOCTYPE html>
<html>
  <head>
    <meta charset='utf8' />
    <title>hello world</title>
  </head>
  <body>
    <div style='color: green'><h1>hello world</h1>
</div>
    <div id='footer'>
      Powered by
      <a href='https://metacpan.org/release/Dancer2'>Dancer2</a>
    </div>
  </body>
</html>
EOF
