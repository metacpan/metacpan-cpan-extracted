use warnings;
use Test::More;
use Data::Dumper;

BEGIN { use_ok( "Bio::Gonzales::Util::Text", "ccount" ); }

my $d;
sub TEST { $d = $_[0]; }

#TESTS

TEST 'basic';
{
    my $string        = "ACTC";
    my $res           = ccount($string);
    my $reference_res = { "A" => 1, 'C' => 2, 'T' => 1 };
    is_deeply( $reference_res, $res, $d );
}

done_testing();
1;
