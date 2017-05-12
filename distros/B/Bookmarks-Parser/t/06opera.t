use lib 'lib';
use Test::More 'no_plan';
use Data::Dumper;

# 1 test load of base class
use_ok('Bookmarks::Parser');

# 2 parse opera style file
my $parser = Bookmarks::Parser->new();
$parser->parse({filename => 't/opera6.adr'});
isa_ok($parser, 'Bookmarks::Opera');

# 3 check root items exist
my @roots = $parser->get_top_level();
is_deeply([ map { $_->{name} } @roots ],
            ['Trash', 'Opera', 'Download.com', 'Amazon.com', 'Dealtime.com', 'eBay', 'Fake eBay' ], 'Found root items');

# 4,5 check we parsed subitems
my @subitems = $parser->get_folder_contents($roots[1]);
is($subitems[0]->{url}, 'http://www.opera.com/download/', 'Found first subitem');
is($subitems[-1]->{url}, 'http://www.opera.com/support/', 'Found last subitem');

# Check that "DISPLAY URL" is understood properly
my $fake_ebay = $roots[6];
is($fake_ebay->{id}, 25, 'Got the fake ebay bookmark id');
is($fake_ebay->{name}, 'Fake eBay', 'Got the fake ebay bookmark name');
is($fake_ebay->{url}, 'http://fake.ebay.com/', 'URL is parsed correctly');
is($fake_ebay->{display_url}, 'http://www.ebay.com/', 'DISPLAY URL is parsed correctly');

# 6 create new opera bookmarks
my $opera = Bookmarks::Opera->new();
isa_ok($opera, 'Bookmarks::Opera');

# 7 set the root item(s)
$opera->set_top_level('root folder');
@roots = $opera->get_top_level();
is($roots[0]->{name}, 'root folder', 'Set root items');

# 8 rename the root folder
is($opera->rename($roots[0], 'new root folder'),
   'new root folder', 'Renamed root item');

# 9 set title
is($parser->set_title('Opera Bookmarks'), 'Opera Bookmarks');

# 10 change to netscape
my $netscape = $parser->as_netscape();
isa_ok($netscape, 'Bookmarks::Netscape');

# 11 output as netscape
my $netscapefile = $netscape->as_string();
# print $operafile;


my $xmlparser = $parser->as_xml();
isa_ok($xmlparser, 'Bookmarks::XML');

my $xmlfile = $xmlparser->as_string();
# print $xmlfile;
ok($xmlfile);

# ----------------------------------------------------
# Open the new Opera 11.50 default bookmarks file
#

# And check that we can do any of this both for DOS and Unix files
for ("t/opera-1150.adr", "t/opera-1150-unix.adr")
{

    my $adr_file = $_;

    $parser = Bookmarks::Parser->new();
    my $parsed = $parser->parse({filename => $adr_file});
    ok($parsed, "'$adr_file' has been loaded");

    isa_ok(
        $parser =>, 'Bookmarks::Opera',
        'Reblessed parser as Bookmarks::Opera'
    );

    @roots = $parser->get_top_level();

    my $trash = $roots[0];
    my $opera = $roots[1];

    is(scalar(@roots) => 2, "Root folder should contain 2 items");
    is($trash->{name}, "Trash", "first item is the trash folder");
    is($trash->{type}, "folder", "Trash is a folder");
    is($trash->{uniqueid}, "14C645A5B8A3470FB3B52CC32C97E2B8");

    is($opera->{name}, "Opera", "second item is the Opera folder");
    is($opera->{type}, "folder", "Opera is a folder");
    is($opera->{uniqueid}, "CFF0FB2AB8F0403BB524F77EF43A30E3", "Opera uniqueid is extracted correctly");

    @subitems = $parser->get_folder_contents($opera);
    is(
        scalar(@subitems) => 19,
        "Check that last bookmark is included in the parsed list"
    );

    my $download = $subitems[0];
    my $myopera = $subitems[1];
    my $sports = $subitems[-1];
    my $myomail = $subitems[-2];

    #iag("download=".Dumper($download));
    #iag("myoperamail=".Dumper($myomail));

    is(
        $sports->{name}, "Sports",
        "Check that we can load the last bookmark correctly"
    );

    is($download->{type}, 'url', 'Bookmark type must be "url"');
    is($download->{id}, 14, 'Check that we got the correct one for real');
    is(
        $download->{uniqueid} => '1E1142BB54F648238B9236643A3183C0',
        'Download Opera uniqueid extracted correctly'
    );
    is(
        $download->{url} => 'http://www.opera.com/download/?utm_source=DesktopBrowser&utm_medium=Bookmark&utm_campaign=BrowserLinks',
        "First bookmark points to Opera.com/download"
    );
    is(
        $myomail->{name} => 'My Opera Mail',
        "Last root bookmark is Mail"
    );
    is(
        $myomail->{partnerid} => "opera-mail2",
        "Partnerid is also extracted"
    );

    is(
        $myomail->{icon} => 'https://mail.opera.com/favicon.ico',
        "Icon extracted correctly",
    );

    is(
        $myomail->{iconfile} => undef,   # 'iconfile' is translated into 'icon'
        "Iconfile property shouldn't be there. Icon is used instead",
    );

    is(
        $myopera->{id} => 15,
        "My Opera bookmark id is correct ($myopera->{id})",
    );

    is(
        $myopera->{name} => 'My Opera Community',
        "My Opera bookmark name is correct"
    );

    is(
        $myopera->{icon} => 'http://redir.opera.com/favicons/myopera/favicon.ico',
        "My Opera icon extracted correctly",
    );

    is(
        $myopera->{on_personalbar} => 'YES',
        "Personal bar flag is parsed correctly",
    );

    is(
        $myopera->{personalbar_pos} => 4,
        "Personal bar position is parsed correctly",
    );

    is(
        $myopera->{partnerid} => 'opera-operasocial',
        "My Opera partnerid is parsed correctly",
    );

}  # DOS and Unix line endings

#
# End of test
