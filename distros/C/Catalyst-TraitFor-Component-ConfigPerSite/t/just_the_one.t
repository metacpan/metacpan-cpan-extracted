use Test::More;
use HTTP::Request;
use HTTP::Request::Common;
use Test::HTML::Form;

use lib qw(t/lib);
use Catalyst::Test qw(TestBlogApp);


my $main_url = '/blog';
my $hr = HTTP::Request->new('GET', $main_url);
$hr->header(Host => 'just.the.one.oh.go.on');
my $r=request($hr);

unless(ok($r->is_success, 'got main blog page ok')) {
    if($r->code == 500) {
	diag "$main_url: internal server error";
	diag "content : \n--------------------------------\n", $r->content, "\n-----------------------------------------\n";
    } else {
	diag "$main_url: ".$r->code;
    }
}

title_matches($r,qr/Yet\sAnother\sBlog\s\(too\)/,'title matches');

tag_matches($r, 'p', { _content => qr/Lorem\sIpsum\setc/ }, 'main content appears as expected' );

no_tag($r, 'div', { class => 'error' }, 'no unexpected errors' );

link_matches($r,qr|/blog/2010/11/firstpost|,'Found link in HTML');

done_testing();
#note "content : \n--------------------------------\n", $r->content, "\n-----------------------------------------\n";
