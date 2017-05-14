
use strict;
use warnings;

use Test::More tests => 4;    # last test to print

use lib 't/lib';
use Catalyst::Test 'TestApp';

my $xml = get('/sitemap');

note $xml;

$xml =~ s/\s+//g;

like $xml, qr{<url><loc>http://localhost/root/alone</loc></url>}, ':Sitemap';
like $xml, qr{<url><loc>http://localhost/root/with_function</loc></url>},
  ':Sitemap(*)';
like $xml,
  qr{<url><loc>http://localhost/root/with_priority</loc><priority>0.75</priority></url>},
  ':Sitemap(0.75)';

like $xml,
  qr{<url><loc>http://localhost/root/with_args</loc><lastmod>2010-09-27</lastmod><changefreq>daily</changefreq></url>},
  ':Sitemap(lotsa stuff)';

