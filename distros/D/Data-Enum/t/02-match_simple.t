use Test::Most;

eval "use match::simple qw(match)";

plan skip_all => "match::simple not installed" if $@;

use_ok("Data::Enum");

ok my $colors = Data::Enum->new(qw/ red green blue /), 'new class';

my $red = $colors->new("red");

can_ok( $red, qw/ MATCH /);

ok match($red, "red");
ok match($red, $red);
ok match($red, $colors->new("red"));

ok !match($red, "pink");
ok !match($red, undef);
ok !match($red, $colors->new("blue"));



done_testing;
