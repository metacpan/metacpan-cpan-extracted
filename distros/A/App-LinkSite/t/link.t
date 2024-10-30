use strict;
use warnings;
use Test::More tests => 5;
use App::LinkSite::Link;

# Test the creation of an App::LinkSite::Link object
my $link = App::LinkSite::Link->new(
    title    => 'Test Title',
    subtitle => 'Test Subtitle',
    link     => 'http://example.com',
    new      => 1,
);
isa_ok($link, 'App::LinkSite::Link', 'Created an App::LinkSite::Link object');

# Test the title method
is($link->title, 'Test Title', 'title method returns "Test Title"');

# Test the subtitle method
is($link->subtitle, 'Test Subtitle', 'subtitle method returns "Test Subtitle"');

# Test the link method
is($link->link, 'http://example.com', 'link method returns "http://example.com"');

# Test the is_new method
is($link->is_new, 1, 'is_new method returns 1');
