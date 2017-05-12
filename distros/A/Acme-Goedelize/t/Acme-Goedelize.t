use Test::More tests => 3;
BEGIN { use_ok('Acme::Goedelize') };

my $goedel = new Acme::Goedelize;

my $string = "cab";
my $number = "39427417418120568083725800";

ok( $goedel->to_number($string) == $number );
ok( $goedel->to_text($number) eq $string );

