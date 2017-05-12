use Test::Simple tests => 5;

use CSS;
my $css = new CSS;
ok(1, "Created the CSS object ok");

#
# SEARCH TESTS
#

$css->read_file("t/css_simple");
ok(1, "Parsed the simple file ok");

my $style = $css->get_style_by_selector('baz');
ok($style, "Got CSS::Style object ok");

my $prop = $style->get_property_by_name('color');
ok($prop, "Got CSS::Property object ok");

ok($prop->{simple_value} eq 'black', "Got property value ok");
