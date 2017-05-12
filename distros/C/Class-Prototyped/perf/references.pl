use Benchmark qw(cmpthese timeit);

package My::Funky::Class;

sub foo {
	print "hi\n";
}

package main;

$My::Funky::Class::mirrors = { $package => 'foo' };

mytimethese(500_000, {
	stringref => sub {
		my %foo = %{"$package\::"};
	},
	'bless_variable' => sub {
		bless {}, $package;
	},
	'bless_constant' => sub {
		bless {}, 'My::Funky::Class';
	},
});



sub get_package {
	my $string = shift;

	my $pkg = \%main::;	foreach (split(/::/, $string)) {$pkg = $pkg->{"$_\::"};}
	return $pkg;
}

sub mytimethese {
	my($iter, $codehash) = @_;

	foreach my $desc (sort keys %$codehash) {
		print "$desc:" . ' 'x(50-length($desc));
		my $time = timeit($iter, $codehash->{$desc});
		print sprintf('%8.2f usec', ($time->[1]+$time->[2])*1_000_000/$time->[5])."\n";
	}
}