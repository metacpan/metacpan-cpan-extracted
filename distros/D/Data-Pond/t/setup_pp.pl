require XSLoader;

my $orig_load = \&XSLoader::load;
no warnings "redefine";
*XSLoader::load = sub {
	die "XS loading disabled for Data::Pond"
		if ($_[0] || "") eq "Data::Pond";
	goto &$orig_load;
};

1;
