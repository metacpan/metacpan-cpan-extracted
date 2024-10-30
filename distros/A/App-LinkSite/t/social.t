use strict;
use warnings;
use Test::More tests => 4;
use App::LinkSite::Social;

# Test the creation of an App::LinkSite::Social object
my $social = App::LinkSite::Social->new(
    service => 'twitter',
    handle  => 'test_handle',
    url     => 'http://example.com',
);
isa_ok($social, 'App::LinkSite::Social', 'Created an App::LinkSite::Social object');

# Test the service method
is($social->service, 'twitter', 'service method returns "twitter"');

# Test the handle method
is($social->handle, 'test_handle', 'handle method returns "test_handle"');

# Test the url method
is($social->url, 'http://example.com', 'url method returns "http://example.com"');
