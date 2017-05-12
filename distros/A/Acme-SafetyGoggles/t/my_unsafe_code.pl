use t::UnsafeSourceFilter;

my $foo = 42;
print "7 times 6 equals $foo\n";

if ($INC{"Acme/SafetyGoggles.pm"}) {
    use Data::Dumper;
    $Data::Dumper::Indent = 0;
    print Data::Dumper::Dumper(
	[ $foo,
	  Acme::SafetyGoggles->state,
	  Acme::SafetyGoggles->diff ] );
}


