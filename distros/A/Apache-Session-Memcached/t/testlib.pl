sub read_config {
	my ($filename,$directives) = @_;
	open(CFG, "$filename") || die "Can't open $filename: $!";
	local $/;
	my $config_line = <CFG>;
	my %config;
	foreach ( split(/\s+/,$directives) ) {
		$config{$_} = get_config($config_line,$_);
 	}
	return %config;
}

sub get_config {
 	my ($config, $param) = @_;
	if ($config =~ /^$param\s*?=\s*(.*?)$/m) {
   	return $1;
	}
	return '';
}

1;
