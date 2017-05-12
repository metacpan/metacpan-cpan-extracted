# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Acme::Jungle::CrawlerExample' ); }
use Data::News;

my $jungle = Acme::Jungle::CrawlerExample->new ();
isa_ok ($jungle, 'Acme::Jungle::CrawlerExample');
$jungle->spider->work_site( 'NewsSpider::Terra', Data::News->new );


