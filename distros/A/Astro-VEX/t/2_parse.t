use strict;

use Test::More tests => 19;

use_ok('Astro::VEX');
use_ok('Astro::VEX::Parse');

my $input; do {local $/ = undef; $input = <DATA>;};

# Try parsing the input.
my $vex = new Astro::VEX(text => $input);
isa_ok($vex, 'Astro::VEX');

# Check that the re-written information matches the input.
my $rewrite = "$vex";
is($rewrite, $input);

# Check various entries from the input.
my $source = ($vex->block('SOURCE')->items)[0];
isa_ok($source, 'Astro::VEX::Def');

is($source->param('source_name')->value, "MySource");
my $value = $source->param('source_name')->item;
isa_ok($value, 'Astro::VEX::Param::String');
is($value->value, "MySource");

$value = $source->param('source_type')->item;
isa_ok($value, 'Astro::VEX::Param::String');
is($value->value, ' planetary " \\ nebula ');

$value = $source->param('number')->item;
isa_ok($value, 'Astro::VEX::Param::Number');
is($value->value, 12);
is($value->unit, undef);

$value = $source->param('frequency')->item;
isa_ok($value, 'Astro::VEX::Param::Number');
is($value->value, 23);
is($value->unit, 'GHz');

$value = $source->param('rate')->item;
isa_ok($value, 'Astro::VEX::Param::Number');
is($value->value + 0, 12200000000);
is($value->unit, 'deg/sec');

__DATA__
VEX_rev = 1.5;
$SOURCE;
def MySource;
*    This is a comment.
     source_name = MySource;
     source_type = " planetary \" \\ nebula ";
     number = 12;
     frequency = 23 GHz;
     rate = .122E+011 deg/sec;
enddef;
