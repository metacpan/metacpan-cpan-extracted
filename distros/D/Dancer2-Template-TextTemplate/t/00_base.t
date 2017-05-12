use Test::More tests => 1;

my $module = 'Dancer2::Template::TextTemplate';
require_ok $module or BAIL_OUT "Can't load $module";

1;
