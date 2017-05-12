require XSLoader;

my $orig_load = \&XSLoader::load;
no warnings "redefine";
*XSLoader::load = sub {
	die "XS loading disabled for Authen::DecHpwd"
		if ($_[0] || "") eq "Authen::DecHpwd";
	goto &$orig_load;
};

1;
