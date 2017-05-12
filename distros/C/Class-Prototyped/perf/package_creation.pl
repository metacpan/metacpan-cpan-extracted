use Benchmark qw(cmpthese);

my $alliter = 5000;

&remote_exec($alliter, '
	package Pack_%i%;
	sub a {"hi";} sub b {"hi";} sub c {"hi";} sub d {"hi";} sub e {"hi";}
');

=head

&remote_exec($alliter, '
	package Pack_%i%;
	@Pack_%i%::ISA = qw(Class::Prototyped);
	Pack_%i%->reflect();
');

&remote_exec($alliter, '
	package Pack_%i%;
	@Pack_%i%::ISA = qw(Class::Prototyped);
	sub foo {"hi";}
	Pack_%i%->reflect();
');

&remote_exec($alliter, '
	package Pack_%i%;
	@Pack_%i%::ISA = qw(Class::Prototyped);
	Pack_%i%->reflect()->addSlot(foo => sub {"hi";});
');

=cut

&remote_exec($alliter, '
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect();
');

=head

&remote_exec($alliter, '
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect();
	Pack_%i%->reflect->_vivified_methods(0);
	Pack_%i%->reflect->_autovivify_methods;
');

&remote_exec($alliter,'
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect->addSlots();
');

&remote_exec($alliter,'
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect->addSlots(); Pack_%i%->reflect->addSlots();
	Pack_%i%->reflect->addSlots(); Pack_%i%->reflect->addSlots();
	Pack_%i%->reflect->addSlots();
');

&remote_exec($alliter,'
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect->addSlots(a => sub {"hi";});
');

&remote_exec($alliter,'
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect->addSlots(a => sub {"hi";});
	Pack_%i%->reflect->addSlots(b => sub {"hi";});
	Pack_%i%->reflect->addSlots(c => sub {"hi";});
	Pack_%i%->reflect->addSlots(d => sub {"hi";});
	Pack_%i%->reflect->addSlots(e => sub {"hi";});
');

=cut

&remote_exec($alliter, '
	package Pack_%i%;
	@Pack_%i%::ISA = qw(Class::Prototyped);
	sub a {"hi";} sub b {"hi";} sub c {"hi";} sub d {"hi";} sub e {"hi";}
	Pack_%i%->reflect();
');

=head

&remote_exec($alliter,'
@main::stuff = ( a => sub {"hi";}, b => sub {"hi";}, c => sub {"hi";},
		d => sub {"hi";}, e => sub {"hi";});
','
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect->addSlots(@main::stuff);
');

=cut

&remote_exec($alliter,'
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect->addSlots( a => sub {"hi";}, b => sub {"hi";},
		c => sub {"hi";},	d => sub {"hi";}, e => sub {"hi";});
');

&remote_exec($alliter,'
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect->addSlots(a => sub {"hi";});
	Pack_%i%->reflect->addSlots(b => sub {"hi";});
	Pack_%i%->reflect->addSlots(c => sub {"hi";});
	Pack_%i%->reflect->addSlots(d => sub {"hi";});
	Pack_%i%->reflect->addSlots(e => sub {"hi";});
');

&remote_exec($alliter,'
	Class::Prototyped->newPackage("Pack_%i%");
	push(@P_%i%::slots, a => sub {"hi";});
	push(@P_%i%::slots, b => sub {"hi";});
	push(@P_%i%::slots, c => sub {"hi";});
	push(@P_%i%::slots, d => sub {"hi";});
	push(@P_%i%::slots, e => sub {"hi";});
	Pack_%i%->reflect->addSlots(@P_%i%::slots);
');

&remote_exec($alliter,'
	Class::Prototyped->newPackage("Pack_%i%");
	push(@P_%i%::slots, a => sub {"hi";}, b => sub {"hi";}, c => sub {"hi";},
		d => sub {"hi";}, e => sub {"hi";});
	Pack_%i%->reflect->addSlots(@P_%i%::slots);
');

&remote_exec($alliter,'
@main::stuff = (f => "f", g => "g", h => "h", i => "i", j => "j");
','
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect->addSlots(@main::stuff);
');

&remote_exec($alliter,'
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect->addSlots(f => "f", g => "g", h => "h",
		i => "i", j => "j");
');

&remote_exec($alliter,'
  $p = Class::Prototyped->new(a => sub {"hi";}, b => sub {"hi";},
		c => sub {"hi";}, d => sub {"hi";}, e => sub {"hi";}, f => "f",
		g => "g", h => "h", i => "i", j => "j");
','
	$Pack_%i% = $p->clone;
');

=head
&remote_exec($alliter,'
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect->addSlots( [qw(a METHOD)] => sub {"hi";},
		[qw(b METHOD)] => sub {"hi";}, [qw(c METHOD)] => sub {"hi";},
		[qw(d METHOD)] => sub {"hi";}, [qw(e METHOD)] => sub {"hi";}
	);
');

&remote_exec(100_000,'
	Class::Prototyped->newPackage("Pack");
	Pack->reflect->addSlots( [qw(a METHOD)] => sub {"hi";},
		[qw(b METHOD)] => sub {"hi";}, [qw(c METHOD)] => sub {"hi";},
		[qw(d METHOD)] => sub {"hi";}, [qw(e METHOD)] => sub {"hi";}
	);
	$main::mirror = Pack->reflect;
','
	$main::mirror->package;
	$main::mirror->_slots;
');

&remote_exec(100_000,'
	Class::Prototyped->newPackage("Pack");
	Pack->reflect->addSlots( [qw(a METHOD)] => sub {"hi";},
		[qw(b METHOD)] => sub {"hi";}, [qw(c METHOD)] => sub {"hi";},
		[qw(d METHOD)] => sub {"hi";}, [qw(e METHOD)] => sub {"hi";}
	);
	$main::mirror = Pack->reflect;
','
	ref(${$main::mirror});
	{
		my $tied = tied(%{ ${ $main::mirror } });
		$main::mirror->_autovivify_parents unless $tied->vivified_parents;
		$main::mirror->_autovivify_methods unless $tied->vivified_methods;
		$tied->slots;
	}
');

&remote_exec($alliter,'
@main::stuff = ( [qw(a METHOD)] => sub {"hi";},
		[qw(b METHOD)] => sub {"hi";}, [qw(c METHOD)] => sub {"hi";},
		[qw(d METHOD)] => sub {"hi";}, [qw(e METHOD)] => sub {"hi";}
	);
','
	Class::Prototyped->newPackage("Pack_%i%");
	Pack_%i%->reflect->addSlots(@main::stuff);
');

=cut

sub remote_exec {
	my($iter, $init, $snippet) = @_;

	unless ($snippet) {
		$snippet = $init;
		$init = '';
	}
	$init =~ s/\t/  /g;
	$snippet =~ s/\t/  /g;

	(my $temp = $snippet) =~ s/\%i\%/123/g;
	my(@lines) = split(/\n/, $temp);
	chomp(my $temp = pop(@lines));
	print $init;
	print join("\n", @lines);
	print "\n$temp" . ' 'x(72-length($temp));

	open(TEMP, "|$^X") or die "Unable to open $^X.\n";
	sleep(1);
	print TEMP "use Class::Prototyped qw(:NO_CHECK);\nuse Benchmark;\nBEGIN {$init\$main::start = Benchmark->new();}\n";
	foreach my $i (1..$iter) {
		(my $temp = $snippet) =~ s/\%i\%/$i/g;
		print TEMP $temp;
	}
	print TEMP "\$main::time = main::timediff(Benchmark->new(), \$main::start);\n";
	print TEMP "print sprintf('%6d'.\"\n\", (\$main::time->[1]+\$main::time->[2])*1_000_000/$iter);\n";
	close TEMP;
}
