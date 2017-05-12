use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 13;

{
    use Dancer;

    eval 'use Dancer::Plugin::SiteMap';
    die $@ if $@;
    ok 1, 'plugin loaded successfully';

    is_deeply $Dancer::Plugin::SiteMap::OMIT_ROUTES,
              undef,
              'no routes omitted during startup';

    sitemap_ignore( '/foo', '/bar/.*' );
    is_deeply $Dancer::Plugin::SiteMap::OMIT_ROUTES,
              [ qw(/foo /bar/.*) ],
              'routes properly set to be omitted';

    # we told sitemap to ignore /foo completely
    get '/foo'         => sub {};
    get '/foo/bar'     => sub {};
    get '/foo/bar/baz' => sub {};
    get '/foo/meep'    => sub {};

    # sitemap should ignore /bar/*, but not /bar itself
    get '/bar'         => sub {};
    get '/bar/baz'     => sub {};
    get '/bar/foo'     => sub {};
    get '/bar/baz/doh' => sub {};

    # only static routes are mapped:
    get '/nono/*'       => sub {};
    get '/nini/:nono'   => sub {};
    get qr/my?pattern/  => sub {};
    get qr/raw_regex/   => sub {};

    # those should be ok!
    get '/moop'         => sub {};
    get '/meep'         => sub {};
    get '/meep/foo'     => sub {};
    get '/meep/bar/baz' => sub {};
}

use Dancer::Test;

route_exists [ GET => '/sitemap'     ], '/sitemap route generated';
route_exists [ GET => '/sitemap.xml' ], '/sitemap.xml route generated';

# we run these tests twice to make sure we can call our routes
# several times and get the same result
foreach (1 .. 2) {
    my $res = dancer_response( GET => '/sitemap.xml' );
    my $expected_xml = <<'EOXML';
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>http://localhost/bar</loc>
  </url>
  <url>
    <loc>http://localhost/meep</loc>
  </url>
  <url>
    <loc>http://localhost/meep/bar/baz</loc>
  </url>
  <url>
    <loc>http://localhost/meep/foo</loc>
  </url>
  <url>
    <loc>http://localhost/moop</loc>
  </url>
  <url>
    <loc>http://localhost/nono/*</loc>
  </url>
  <url>
    <loc>http://localhost/sitemap</loc>
  </url>
  <url>
    <loc>http://localhost/sitemap.xml</loc>
  </url>
</urlset>
EOXML

    is $res->status, 200, "got /sitemap.xml (turn: $_)";
    is $res->content, $expected_xml, "got the proper sitemap.xml content (turn: $_)";

    $res = dancer_response( GET => '/sitemap' );
    my $expected_html = <<'EOHTML';
<h2>Site Map</h2>
<ul class="sitemap">
  <li><a href="/bar">/bar</a></li>
  <li><a href="/meep">/meep</a></li>
  <li><a href="/meep/bar/baz">/meep/bar/baz</a></li>
  <li><a href="/meep/foo">/meep/foo</a></li>
  <li><a href="/moop">/moop</a></li>
  <li><a href="/nono/*">/nono/*</a></li>
  <li><a href="/sitemap">/sitemap</a></li>
  <li><a href="/sitemap.xml">/sitemap.xml</a></li>
</ul>
EOHTML

    is $res->status, 200, "got /sitemap (turn: $_)";
    is $res->content, $expected_html, "got the proper sitemap content (turn: $_)";
}

