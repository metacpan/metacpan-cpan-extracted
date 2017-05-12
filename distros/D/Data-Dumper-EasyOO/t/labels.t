#!perl
use strict;
use Test::More (tests => 54);
use vars qw( $AR $HR @ARGold @HRGold @ArraysGold @LArraysGold @Arrays);
require "t/TestLabelled.pm";
use strict;

use_ok q(Data::Dumper::EasyOO);
my $ezdd = Data::Dumper::EasyOO->new();

is($ezdd->(t1=>2,t3=>4), <<'EORef', "auto-label on array of 4 ints");
$t1 = 2;
$t3 = 4;
EORef

is($ezdd->('one',2,'three',4), <<'EORef', "auto-label on 4 elem array");
$one = 2;
$three = 4;
EORef

SKIP: {
    skip '- list-of-refs \(1..4) unsupported in this perl',1 if $] < 5.008;
    is($ezdd->(\(1..4)), <<'EORef', "no labels on array of refs");
$VAR1 = \1;
$VAR2 = \2;
$VAR3 = \3;
$VAR4 = \4;
EORef
}

# uses a single object repeatedly, invokes with label => $data syntax
pass "test auto-labelling with combos of Terse(T), Indent(I)";

for my $t (0..1) {
    pass "following with Terse($t)";
    $ezdd->Terse($t);

    for my $i (0..3) {
	$ezdd->Indent($i);

	is ($ezdd->("indent$i" => $AR), $ARGold[$t][$i]
	    , "labeled AR, with Indent($i)" );
	is ($ezdd->("indent$i" => $HR), $HRGold[$t][$i]
	    , "labeled HR, with Indent($i)" );
    }
}

pass "two labeled data items, with combos of Terse(T), Indent(I)";

for my $t (0..1) {
    pass "following with Terse($t)";
    $ezdd->Terse($t);

    for my $i (0..3) {
	$ezdd->Indent($i);

	is ($ezdd->("indent$i" => $AR, "indent$i" => $HR)
	    , "$ARGold[$t][$i]" . "$HRGold[$t][$i]"
	    , "labeled AR and HR, with Indent($i)" );
    }
}

$ezdd->Set(Terse=>0,Indent=>2); # restore behavior matching DD default

pass "test un-labelling";	# exposed a bug!

for my $i (0..$#Arrays) {
    is ($ezdd->("item$i" => $Arrays[$i]), $LArraysGold[$i], "labeled-data[$i]");
    is ($ezdd->($Arrays[$i]),		  $ArraysGold[$i], "unlabeled-data[$i]");
}

pass "test programmer intended labelling, right and wrong";

for my $i (0..$#Arrays-1) {
    my $j = $i+1;
    is ($ezdd->("item$i" => $Arrays[$i], "item$j" => $Arrays[$j])
	, $LArraysGold[$i].$LArraysGold[$j],
	, "labeled-data[$i] and labeled-data[$j]");

    isnt ($ezdd->("item$i" => $Arrays[$i], $Arrays[$j])
	    , $LArraysGold[$i].$LArraysGold[$j],
	    , "labeled-data[$i] and un-labeled-data[$j]");
}

__END__

