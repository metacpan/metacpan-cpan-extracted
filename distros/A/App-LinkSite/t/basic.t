use strict;
use warnings;
use Test::More tests => 3;
use FindBin '$Bin';
use App::LinkSite;

# Test the creation of an App::LinkSite object
my $linksite = App::LinkSite->new(file => 't/links.json');
isa_ok($linksite, 'App::LinkSite', 'Created an App::LinkSite object');

# Test the src method
is($linksite->src, "$Bin/../src", 'src method returns "src"');

# Test the out method
is($linksite->out, 'docs', 'out method returns "docs"');
