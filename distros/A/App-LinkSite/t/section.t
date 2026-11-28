use strict;
use warnings;
use Test::More;
use App::LinkSite::Section;
use App::LinkSite::Link;

# Test the creation of an App::LinkSite::Section object with links
my $link1 = App::LinkSite::Link->new(
    title => 'Test Link 1',
    link  => 'http://example.com/1',
);
my $link2 = App::LinkSite::Link->new(
    title => 'Test Link 2',
    link  => 'http://example.com/2',
);

my $section = App::LinkSite::Section->new(
    title => 'Test Section',
    links => [$link1, $link2],
);
isa_ok($section, 'App::LinkSite::Section', 'Created an App::LinkSite::Section object');

# Test the title method
is($section->title, 'Test Section', 'title method returns "Test Section"');

# Test the links method
is(scalar @{$section->links}, 2, 'section has 2 links');
isa_ok($section->links->[0], 'App::LinkSite::Link', 'first link is a Link object');
isa_ok($section->links->[1], 'App::LinkSite::Link', 'second link is a Link object');

# Test the has_links method
ok($section->has_links, 'has_links returns true when section has links');

# Test empty section
my $empty_section = App::LinkSite::Section->new(
    title => 'Empty Section',
    links => [],
);
ok(!$empty_section->has_links, 'has_links returns false when section has no links');

done_testing;
