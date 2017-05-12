# Regression test for RT #18238

use strict;
use warnings;
use Test::More tests => 11;

use Bookmarks::Parser;
use Data::Dumper;

my $test_file = "t/rt18238.html";
my $parser = Bookmarks::Parser->new();
my $bookmarks = $parser->parse({filename => $test_file});

ok($bookmarks, "Parsed the sample test file");

my @exported;

for my $type (qw(netscape opera xml)) {
    my $fname = "t/test.$type.$$.html";
    push @exported, $fname;
    $bookmarks->write_file({
        filename => $fname,
        type => $type,
    });
}

my @contents;
for my $fname (@exported) {
    my $str = "";
    open my $fh, '<', $fname or die "Can't open file $fname: $!";
    binmode $fh;
    $str .= $_ while readline $fh;
    close $fh;
    ok($str, "$fname exported and read back correctly");
    push @contents, $str;
}

my $netscape_export = $contents[0];
my $opera_export = $contents[1];
my $xml_export = $contents[2];
undef @contents;

ok($netscape_export ne $opera_export, "Netscape write format != Opera write format");
ok($netscape_export ne $xml_export,   "Netscape write format != XML write format");
ok($opera_export    ne $xml_export,   "Opera write format != XML write format");

like($netscape_export => qr{^<!DOCTYPE NETSCAPE-Bookmark-file-1>}m,
    "Netscape format is exported correctly"
);

like($opera_export => qr{Opera Hotlist version \d+\.\d+}m,
    "Opera format is exported correctly"
);

like($xml_export => qr{^<\?xml version="1\.0" encoding="UTF-8"\?>},
    "XML format is exported correctly"
);

is(unlink(@exported) => scalar(@exported), "Removed temporary files");

#
# End of test
