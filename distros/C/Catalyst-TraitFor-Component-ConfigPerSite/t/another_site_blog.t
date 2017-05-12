use Test::More tests => 5;
use HTTP::Request;
use HTTP::Request::Common;
use Test::HTML::Form;

use lib qw(t/lib);
use Catalyst::Test qw(TestBlogApp);


my $main_url = '/blog';
my $hr = HTTP::Request->new('GET', $main_url);
$hr->header(Host => 'foo.bar');
my $r=request($hr);

unless(ok($r->is_success, 'got main blog page ok')) {
    if($r->code == 500) {
	diag "$main_url: internal server error";
	diag "content : \n--------------------------------\n", $r->content, "\n-----------------------------------------\n";
    } else {
	diag "$main_url: ".$r->code;
    }
}

title_matches($r,qr/A\sN\sOther/,'title matches');

tag_matches($r, 'p', { _content => qr/The\sclock\sstruck\s13/ }, 'main content appears as expected' );

#warn "\ncontent : \n", $r->content, "\n\n";

no_tag($r, 'div', { class => 'error' }, 'no unexpected errors' );

link_matches($r,qr|/blog/2010/11/firstpost|,'Found link in HTML');

#note "content : \n--------------------------------\n", $r->content, "\n-----------------------------------------\n";
