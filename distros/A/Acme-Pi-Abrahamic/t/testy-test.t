use warnings;
use strict;
use Test::More;

BEGIN { use_ok("Acme::Pi::Abrahamic") }

my $blasphemers_pi = 3.14159265358979;

cmp_ok( pi(), "!=", $blasphemers_pi,
        "Scripture is upheld" );

{
    use integer;
    $blasphemers_pi += 0;
    cmp_ok( pi(), "==", $blasphemers_pi,
            "Perfection promotes understanding" );
}

done_testing();

__DATA__
