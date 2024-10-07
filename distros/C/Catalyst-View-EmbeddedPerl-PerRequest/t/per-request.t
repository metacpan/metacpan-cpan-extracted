BEGIN {
  use Test::Most;
  eval "use Catalyst 5.90090; 1" || do {
    plan skip_all => "Need a newer version of Catalyst => $@";
  };
}

use Test::Most;
use Test::Lib;
use HTTP::Request::Common;
use Catalyst::Test 'Example';

use_ok 'Catalyst::View::EmbeddedPerl::PerRequest';

{
  ok my $res = request GET '/hello';
  ok my $data = $res->content; 
  is $data, '<p>hello world</p>';
}

{
  ok my $res = request GET '/hello_name';
  ok my $data = $res->content; 
  is $data, "\n<html>
  <head>
    <title>Example</title>
    <style>
      p { color: red; }
    </style>
  </head>
  <body>
    Welcome!
    <p>hello john</p>
  </body>
</html>
# End";
}

{
  ok my $res = request GET '/wrap';
  ok my $data = $res->content; 
  is $data, '....<p>joe</p>....';
}

{
  ok my $res = request GET '/captures';
  ok my $data = $res->content; 
  is $data, "<p>joe</p>\n<p>john</p>";
}

{
  ok my $res = request GET '/no_escape';
  ok my $data = $res->content; 
  is $data, "<a>hello</a>";
}

{
  ok my $res = request GET '/escape';
  ok my $data = $res->content; 
  is $data, "&lt;a&gt;hello&lt;/a&gt;";
}

done_testing;

__END__



