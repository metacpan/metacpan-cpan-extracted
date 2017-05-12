use strict;
use warnings;
use Test::More import => ['!pass'];
plan tests => 12;

my $robots_file = -d 't' ? 't/robots.txt' : 'robots.txt';

{
    use Dancer;

    # settings must be loaded before we load the plugin
    setting(plugins => {
        SiteMap => {
            robots_disallow => $robots_file,
        },
    });


    eval 'use Dancer::Plugin::SiteMap';
    die $@ if $@;
    ok 1, 'plugin loaded successfully';

    is_deeply $Dancer::Plugin::SiteMap::OMIT_ROUTES,
              [ qw(/foo /bar/) ],
              'routes properly set to be omitted';

    # let's add to the robots.txt ignore list
    sitemap_ignore( '/nono+' );

    # our robots.txt told sitemap to ignore the "/foo" base string completely
    get '/foo'         => sub {};
    get '/foobar'      => sub {};
    get '/foo/bar'     => sub {};
    get '/foo/meep'    => sub {};

    # sitemap should ignore /bar/*, but not /bar itself
    get '/bar'         => sub {};
    get '/bar/baz'     => sub {};
    get '/bar/foo'     => sub {};
    get '/bar/baz/doh' => sub {};

    # those we excluded via sitemap_ignore()
    get '/nono'        => sub {};
    get '/nonooooo'    => sub {};

    # those should be ok!
    get '/moop'         => sub {};
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
    <loc>http://localhost/meep/bar/baz</loc>
  </url>
  <url>
    <loc>http://localhost/meep/foo</loc>
  </url>
  <url>
    <loc>http://localhost/moop</loc>
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
  <li><a href="/meep/bar/baz">/meep/bar/baz</a></li>
  <li><a href="/meep/foo">/meep/foo</a></li>
  <li><a href="/moop">/moop</a></li>
  <li><a href="/sitemap">/sitemap</a></li>
  <li><a href="/sitemap.xml">/sitemap.xml</a></li>
</ul>
EOHTML

    is $res->status, 200, "got /sitemap (turn: $_)";
    is $res->content, $expected_html, "got the proper sitemap content (turn: $_)";
}

