package main;

#
# Default behavior, EXCEPT:
#    fill_password => 0
#

use Test::More tests => 3;
use lib 't/lib';
use Catalyst::Test 'TestApp4';

use HTML::Parser ();
my $p = HTML::Parser->new(
   start_h => [\&html_parser_start, "self,tagname,attr"],
);

my $url = '/?aaa=one&bbb=two&ccc=three&ddd=four';

my $parsed_html;
{
    ok( my $response = request($url), 'Normal Request'  );
    is( $response->code, 200,         'OK status code'  );
    $p->parse($response->content);
    is( $parsed_html,
        "form1:aaa|one|bbb|two|ccc|three|ddd||" .
        "form2:aaa|one|bbb|two|ccc|three|ddd||",
                                      'Re-Parsed HTML'  );
}


sub html_parser_start {
    my($self, $tag, $attr) = @_;
    if ($tag eq "form") {
       $parsed_html .= $attr->{name} . ":";
    } elsif ($tag eq "input") {
       $parsed_html .= sprintf("%s|%s|", $attr->{name}, $attr->{value});
    }
}



