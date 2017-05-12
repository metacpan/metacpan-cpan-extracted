use Test::More tests => 3;
use Data::Dumper;

use Bookmarks::Parser;

my $parser = Bookmarks::Parser->new();
my $combined_bookmarks = $parser->parse({filename => 't/rt18894.xml'});
ok($combined_bookmarks, "Parsed the xml file");

my $as_xml = $combined_bookmarks->as_xml()->as_string();
ok($as_xml, "Got some xml output");

# Url is included in the xml output
like($as_xml, qr{<bookmark .* url="http://www\.perlmonks\.org}x,
    "Bookmark url is included in the XML output"
);

#
# End of test
