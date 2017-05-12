package MySite::CSS;
use CSS::Moonfall;
our $page_width = 1000;
our $colors = { background => '#000000', color => '#FFFFFF' };

package main;
use Test::More tests => 1;
my $got = MySite::CSS->filter(<<'CSS');
body { width: [page_width]; }
#header { width: [$page_width-20]; [colors] }
CSS

my $expected = <<'CSS';
body { width: 1000px; }
#header { width: 980px; background: #000000; color: #FFFFFF; }
CSS

is($got, $expected, "Synopsis works");

