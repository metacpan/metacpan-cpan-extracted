use strict;
use warnings;
use Test::More;
use lib qw(t/lib);
use MyTest;

# testing get by id
{ 
	test_json(
		GET("/twitter/tweet/id1"),
		{ get => { id => "id1", type => "tweet", index => "twitter" }, _source => { foo => "bar" } },
	);
}

# testing raw_get
{ 
	test_json(
		GET("/twitter/user/id1"),
		{ foo => "bar" },
	);
}


done_testing;