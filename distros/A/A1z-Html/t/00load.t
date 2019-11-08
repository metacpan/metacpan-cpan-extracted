use Test::More qw(no_plan);
BEGIN { use_ok('A1z::Html') };

my $h = new A1z::Html;
is( $h->VERSION, 0.003, "Version Check");
