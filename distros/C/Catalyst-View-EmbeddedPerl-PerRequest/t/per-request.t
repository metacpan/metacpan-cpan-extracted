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
  is $data, "\n\n\n<html>
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

{
  ok my $res = request GET '/inherit';
  ok my $data = $res->content;


  is $data, "<html>
  <head>
    <title>Inherited Title: 1</title>
    <style>
      p { color: red; }
    </style>
  </head>
  <body>ccc1
    Inherited Title
    


joe1
joe2
joe3
joe4
1
bbb1
ccc1
  <p>hello world</p>
  </body>
</html>";

}

{
  ok my $res = request GET '/attributes';
  ok my $data = $res->content;
  is $data, '<tag
  foo="1"
  style="font: big"
  class="aaa"
  checked
  selected
  disabled
  readonly
  required
  href="http://example.comvvv"
  src="http://example.comvvv"
>
<tag foo="1" class="aaa bbb" data-aaa="foo" data-bbb="bar">';
}

{
  ok my $res = request GET '/stringification';
  ok my $data = $res->content;
  is $data, '<p>JohnDoe</p>
<p>
    <div>John</div>
    <div>Doe</div>
</p>';
}

done_testing;

__END__

