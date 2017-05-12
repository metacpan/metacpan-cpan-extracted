use Test::More tests => 2;
use Test::CGI::Untaint;

is_extractable("<a>foobar", "<a>foobar</a>\n", "html");
is_extractable("<div class=\"foo\"><xyz>foo</xyz></div>", "<div>foo</div>\n", 
               "html");
