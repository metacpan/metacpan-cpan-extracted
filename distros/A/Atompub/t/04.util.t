use strict;
use warnings;
#use Data::Dumper; $Data::Dumper::Indent = 1;
use Test::More tests => 25;

use Atompub::MediaType qw(media_type);
use Atompub::Util qw(is_acceptable_media_type is_allowed_category);
use XML::Atom::Service;

# is_acceptable_media_type

my $coll = XML::Atom::Collection->new;

ok  is_acceptable_media_type($coll, media_type('entry'));
ok !is_acceptable_media_type($coll, 'image/png');

$coll->accept('application/xml');
ok  is_acceptable_media_type($coll, media_type('entry'));
ok !is_acceptable_media_type($coll, 'image/png');

$coll->accept(media_type('entry'));
ok  is_acceptable_media_type($coll, media_type('entry'));
ok !is_acceptable_media_type($coll, 'image/png');

$coll->accept('image/png');
ok !is_acceptable_media_type($coll, media_type('entry'));
ok  is_acceptable_media_type($coll, 'image/png');

$coll->accept('image/*');
ok !is_acceptable_media_type($coll, media_type('entry'));
ok  is_acceptable_media_type($coll, 'image/png');

$coll->accept('image/png', 'image/jpeg', 'image/gif');
ok !is_acceptable_media_type($coll, media_type('entry'));
ok  is_acceptable_media_type($coll, 'image/png');

$coll->accept('image/png,image/jpeg,image/gif');
ok !is_acceptable_media_type($coll, media_type('entry'));
ok  is_acceptable_media_type($coll, 'image/png');


# is_allowed_category

my $cat1 = XML::Atom::Category->new;
$cat1->term('animal');
my $cat1_s = XML::Atom::Category->new;
$cat1_s->term('animal');
$cat1_s->scheme('http://example.com/cats/big3');
my $cat2 = XML::Atom::Category->new;
$cat2->term('vegetable');

my $cats = XML::Atom::Categories->new;
$coll->categories($cats);
ok is_allowed_category($coll, $cat1);

$cats->fixed('yes');
ok !is_allowed_category($coll, $cat1);

$cats->category($cat1);
ok  is_allowed_category($coll, $cat1);
ok  is_allowed_category($coll, $cat1_s);
ok !is_allowed_category($coll, $cat1, $cat2);

$cats->category($cat1_s);
ok !is_allowed_category($coll, $cat1);
ok  is_allowed_category($coll, $cat1_s);

$cats->category($cat1, $cat2);
ok is_allowed_category($coll, $cat1, $cat2);

$cats->category($cat1);
$cats->scheme('http://example.com/cats/big3');
ok !is_allowed_category($coll, $cat1);
ok  is_allowed_category($coll, $cat1_s);


$coll = XML::Atom::Collection->new; # no app:categories

ok is_allowed_category($coll, $cat1);
