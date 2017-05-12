use Test::More tests => 4;


TODO: {
    local $TODO = "Acme::SafetyGoggles produces false positives when source filtering has limited scope";

    $ENV{TOGGLE} = 'OFF';
    chomp(my @v = 
	qx($^X -Iblib/lib -MAcme::SafetyGoggles t/use-no.pl));
    ok(@v >= 2 && $v[0] eq '$foo minus $bar is 0', 
	'unfiltered code has right result' );
    my $w = eval join "\n", @v[1..$#v];
    ok(ref $w eq 'ARRAY' &&
	$w->[0] == 19 &&
	$w->[1] == 19 &&
	$w->[2] eq 'safe' &&
	$w->[3] eq '',
	'unfiltered code correct, certified safe');
}

$ENV{TOGGLE} = 'ON';
chomp(my @v = 
	qx($^X -Iblib/lib -MAcme::SafetyGoggles t/use-no.pl));
ok(@v >= 2 && $v[0] ne '$foo minus $bar is 0', 
	'filtered code has right result' )
	or diag @v;
my $w = eval join "\n", @v[1..$#v];
ok(ref $w eq 'ARRAY' &&
   $w->[0] == 42 &&
   $w->[1] == 19 &&
   $w->[2] eq 'unsafe' &&
   $w->[3] ne '',
   'filtered code incorrect, modification detected');

