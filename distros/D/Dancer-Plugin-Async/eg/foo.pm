async '/foo' => sub {
	my $respond = respond;
	my $t; $t = AE::timer(1, 0, sub {
		undef $t;
		$respond->([ 200, [], [ 'foo!' ]]);
	});
};
