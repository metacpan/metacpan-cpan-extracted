use Test::Simple tests => 7;

use CSS;
my $css = CSS->new();
ok( (defined($css) and ref $css eq 'CSS'), "CSS::new() works");

use CSS::Parse::Lite;
my $css_lite = CSS::Parse::Lite->new();
ok( (defined($css_lite) and ref $css_lite eq 'CSS::Parse::Lite'), 'CSS::Parse::Lite::new() works' );

use CSS::Parse::Heavy;
my $css_heavy = CSS::Parse::Heavy->new();
ok( (defined($css_heavy) and ref $css_heavy eq 'CSS::Parse::Heavy'), 'CSS::Parse::Heavy::new() works' );

use CSS::Style;
my $css_style = CSS::Style->new();
ok( (defined($css_style) and ref $css_style eq 'CSS::Style'), 'CSS::Style::new() works' );

use CSS::Selector;
my $css_selector = CSS::Selector->new();
ok( (defined($css_selector) and ref $css_selector eq 'CSS::Selector'), 'CSS::Selector::new() works' );

use CSS::Property;
my $css_property = CSS::Property->new();
ok( (defined($css_property) and ref $css_property eq 'CSS::Property'), 'CSS::Property::new() works' );

use CSS::Value;
my $css_value = CSS::Value->new();
ok( (defined($css_value) and ref $css_value eq 'CSS::Value'), 'CSS::Value::new() works' );

