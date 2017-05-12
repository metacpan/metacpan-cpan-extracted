#!/usr/bin/perl

use lib 'lib';
use Test::More;
if ($ENV{DELUSER} && $ENV{DELPASS}) {
   plan tests => 6;
} else {
    plan skip_all => 'This test requires login. set DELUSER and DELPASS to enable this test' ;
}

# 1 test load of base class
use_ok('Bookmarks::Parser');

my $parser = Bookmarks::Parser->new();
# 2 create base class
isa_ok($parser, 'Bookmarks::Parser');
# 3 check parse function
can_ok('Bookmarks::Parser', 'parse');

# 4 parse netscape style file
$parser->parse({user => $ENV{DELUSER},
                url => 'del.icio.us',
                passwd => $ENV{DELPASS}});
isa_ok($parser, 'Bookmarks::Delicious');

# 5 check root items exist
my @roots = $parser->get_top_level();

#is($roots[0]->{name}, 'Personal Toolbar Folder', 'Found root item');

# # 6,7 check we parsed all subitems
# my @subitems = $parser->get_folder_contents($roots[0]);
# is($subitems[0]->{url}, 'http://home.netscape.com/bookmark/4_05/ptmembers.html?t', 'Found first subitem');
# is($subitems[-1]->{url}, 'http://home.netscape.com/bookmark/4_05/ptmarketplace.html?t', 'Found last subitem');

# # 8 recreate input file as string
# my $origfile = $parser->as_string();
# # print $origfile;

# # 8 create new netscape bookmarks
# my $netscape = Bookmarks::Netscape->new();
# isa_ok($netscape, 'Bookmarks::Netscape');

# # 9 set the root item(s)
# $netscape->set_top_level('root folder');
# @roots = $netscape->get_top_level();
# is($roots[0]->{name}, 'root folder', 'Set root items');

# # 10 rename the root folder
# is($netscape->rename($roots[0], 'new root folder'), 
#    'new root folder', 'Renamed root item');

# 11 change to opera
my $opera = $parser->as_opera();
isa_ok($opera, 'Bookmarks::Opera');

# 12 output as opera
my $operafile = $opera->as_string();
print $operafile;


my $xmlparser = $parser->as_xml();
isa_ok($xmlparser, 'Bookmarks::XML');
my $xmlfile = $xmlparser->as_string();
print $xmlfile;
