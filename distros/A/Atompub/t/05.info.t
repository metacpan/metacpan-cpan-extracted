use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 18;

use Atompub::Client;
use XML::Atom::Service;

# instance

my $info = Atompub::Client::Info->instance;
isa_ok $info, 'Atompub::Client::Info';

# put and get a resource, which has app:categories

my $cats = XML::Atom::Categories->new;
$cats->fixed( 'yes' );
$cats->scheme( 'http://example.com/cats/big3' );

my $cat = XML::Atom::Category->new;
$cat->term( 'animal' );
$cats->add_category( $cat );

$cat = XML::Atom::Category->new;
$cat->term( 'vegetable' );
$cats->add_category( $cat );

$cat = XML::Atom::Category->new;
$cat->term( 'mineral' );
$cat->scheme( 'http://example.com/dogs/big3' );
$cats->add_category( $cat );

my $coll = XML::Atom::Collection->new;
$coll->title( 'Text' );
$coll->href( 'http://example.com/text' );
$coll->add_categories( $cats );

$info->put( $coll->href, $coll );
$coll = $info->get( $coll->href );
isa_ok $coll, 'XML::Atom::Collection';

is $coll->title, 'Text';
is $coll->href, 'http://example.com/text';
is $coll->accept, undef;
is $coll->categories->fixed, 'yes';
is $coll->categories->scheme, 'http://example.com/cats/big3';

my @cat = $coll->categories->category;
is $cat[0]->term, 'animal';
is $cat[0]->scheme, undef;
is $cat[1]->term, 'vegetable';
is $cat[1]->scheme, undef;
is $cat[2]->term, 'mineral';
is $cat[2]->scheme, 'http://example.com/dogs/big3';

# put and get a resource, which has app:accept

$coll = XML::Atom::Collection->new;
$coll->title( 'Photo' );
$coll->href( 'http://example.com/photo' );
$coll->accept( 'image/png', 'image/jpeg', 'image/gif' );

$info->put( $coll->href, $coll );
$coll = $info->get( $coll->href );
isa_ok $coll, 'XML::Atom::Collection';

my @accepts = $coll->accepts;
is $accepts[0], 'image/png';
is $accepts[1], 'image/jpeg';
is $accepts[2], 'image/gif';

# remove a resource

$info->put( $coll->href );
is $info->get( $coll->href ), undef;
