#!/usr/bin/perl -w

use strict;

use ContentManager::Page;
use ContentManager::Image;
use Data::Dumper;

my $page = ContentManager::Page->create( {title=>'Extending Class::DBI', date_to_publish=>'dd/mm/yyyy'});

my ($image1) = ContentManager::Image->search(name=>'Class::DBI logo');
my @figures = ContentManager::Image->search(name=>'Class Diagram (CDBI)', {order_by => 'filename'});
my ($author_image) = ContentManager::Image->search(name=>'Aaron Trevena - portrait');
my ($delete_me) = ContentManager::Image->search(filename=>'delete.jpg');
my ($delete_me_too) = ContentManager::Image->search(filename=>'delete2.jpg');

# warn Dumper(@figures);

$page->insert_Images([@figures]); # inserts figures into next/last available positions, sets positions

$page->prepend_to_Images($image1->id); # inserts image into first position, resets other image positions

$page->append_to_Images($author_image); # appends image to last position

$page->insert_Images($delete_me, 2); # insert image at position

$page->insert_Images($delete_me_too, 3); # insert image at position

print "relationships built\n";
my @all_images = $page->Images;
print Dumper(@all_images);

print "deleting image in position 2\n";
$page->delete_Images(2); # delete image by position

@all_images = $page->Images;
print Dumper(@all_images);

print "deleting image matching object\n";
$page->delete_Images(object => $delete_me_too); # delete image by object

@all_images = $page->Images;
print Dumper(@all_images);
