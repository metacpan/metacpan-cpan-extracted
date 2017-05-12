use Test::More tests => 3; 
use strict;
use warnings;

use_ok( 'XML::Atom::Feed::JavaScript' );

my $feed = XML::Atom::Feed::JavaScript->new(Stream => 't/feed.xml');

## blessed into correct package
isa_ok( $feed, 'XML::Atom::Feed::JavaScript' ); 

## check the title is ok from XML::Atom::Feed::JavaScript
is( $feed->title(), "dive into atom", 'title() works ok' );

