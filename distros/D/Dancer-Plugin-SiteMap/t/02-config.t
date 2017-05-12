use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 13;

{
    use Dancer;

    # settings must be loaded before we load the plugin
    setting(plugins => {
        SiteMap => {
            xml_route  => '/my/xml/sitemap',
            html_route => '/my/html',
        },
    });

    eval 'use Dancer::Plugin::SiteMap';
    die $@ if $@;
    ok 1, 'plugin loaded successfully';

    get '/foo/bar' => sub {};
    get '/bar'     => sub {};
    get '/moop'    => sub {};
}

use Dancer::Test;

route_doesnt_exist [ GET => '/sitemap'     ], '/sitemap route override';
route_doesnt_exist [ GET => '/sitemap.xml' ], '/sitemap.xml route override';

route_exists [ GET => '/my/xml/sitemap' ], '/my/xml/sitemap override';
route_exists [ GET => '/my/html'        ], '/my/html override';

# we run these tests twice to make sure we can call our routes
# several times and get the same result
foreach (1 .. 2) {
    my $res = dancer_response( GET => '/my/xml/sitemap' );
    my $expected_xml = <<'EOXML';
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>http://localhost/bar</loc>
  </url>
  <url>
    <loc>http://localhost/foo/bar</loc>
  </url>
  <url>
    <loc>http://localhost/moop</loc>
  </url>
  <url>
    <loc>http://localhost/my/html</loc>
  </url>
  <url>
    <loc>http://localhost/my/xml/sitemap</loc>
  </url>
</urlset>
EOXML

    is $res->status, 200, "got /my/xml/sitemap (turn: $_)";
    is $res->content, $expected_xml, "got the proper xml content (turn: $_)";

    $res = dancer_response( GET => '/my/html' );
    my $expected_html = <<'EOHTML';
<h2>Site Map</h2>
<ul class="sitemap">
  <li><a href="/bar">/bar</a></li>
  <li><a href="/foo/bar">/foo/bar</a></li>
  <li><a href="/moop">/moop</a></li>
  <li><a href="/my/html">/my/html</a></li>
  <li><a href="/my/xml/sitemap">/my/xml/sitemap</a></li>
</ul>
EOHTML

    is $res->status, 200, "got /sitemap (turn: $_)";
    is $res->content, $expected_html, "got the proper sitemap content (turn: $_)";
}

