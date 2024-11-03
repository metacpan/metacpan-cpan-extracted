use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use App::LinkSite;

# Test the creation of an App::LinkSite object
my $linksite = App::LinkSite->new(file => 't/links.json');
isa_ok($linksite, 'App::LinkSite', 'Created an App::LinkSite object');

# Test the src method
TODO: {
  local $TODO = 'Figure out how to use this with File::ShareDir';
  is($linksite->src, "$Bin/../src", 'src method returns "src"');
}

# Test the out method
is($linksite->out, 'docs', 'out method returns "docs"');

# Test the ga4 method
is($linksite->ga4, 'GA4-Dummy', 'ga4 method returns "GA4-Dummy"');

# Test the font_awesome_kit method
is($linksite->font_awesome_kit, 'FA-Dummy', 'font_awesome_kit method returns "FA-Dummy"');

done_testing;
