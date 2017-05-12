# a script that turns filtering on and off
use t::ToggledSourceFilter;

my $foo = 19;

no t::ToggledSourceFilter;

my $bar = 19;

print "\$foo minus \$bar is ", $foo-$bar, "\n";

if ($INC{"Acme/SafetyGoggles.pm"}) {
    use Data::Dumper;
    $Data::Dumper::Indent = 0;
    print Data::Dumper::Dumper(
	[ $foo, $bar,
	  Acme::SafetyGoggles->state,
	  Acme::SafetyGoggles->diff ] );
}


