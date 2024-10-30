use strict;
use warnings;
use Test::More tests => 7;
use App::LinkSite::Site;

# Test the creation of an App::LinkSite::Site object
my $site = App::LinkSite::Site->new(
    name     => 'Test Name',
    handle   => 'Test Handle',
    image    => 'test_image.jpg',
    desc     => 'Test Description',
    og_image => 'test_og_image.png',
    site_url => 'http://example.com',
);
isa_ok($site, 'App::LinkSite::Site', 'Created an App::LinkSite::Site object');

# Test the name method
is($site->name, 'Test Name', 'name method returns "Test Name"');

# Test the handle method
is($site->handle, 'Test Handle', 'handle method returns "Test Handle"');

# Test the image method
is($site->image, 'test_image.jpg', 'image method returns "test_image.jpg"');

# Test the desc method
is($site->desc, 'Test Description', 'desc method returns "Test Description"');

# Test the og_image method
is($site->og_image, 'test_og_image.png', 'og_image method returns "test_og_image.png"');

# Test the site_url method
is($site->site_url, 'http://example.com', 'site_url method returns "http://example.com"');
