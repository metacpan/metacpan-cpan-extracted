use strict;
use warnings;
use Test::More;
use lib qw(t/lib);
use MyTest;

test_json(
	GET("/twitter"),
	{search => {index => "twitter"}}
);

# testing allow_scripts
{ 
	test_json(
		POST("/twitter", Content => encode_json($_)),
		{ code => 416, message => "'script' fields are not allowed"}
	) for(
		{script => {foo => 1}},
		{query => { bool => { and => [{term => {1 => 2}},{script => {foo => 1}}]}}},
	);
}

# testing max_size
{
	test_json(
		GET("/twitter?size=500"),
		{search => {size => 500, index => "twitter"}},
		"GET with size <= 5000 ok"
	);

	test_json(
		POST("/twitter", Content => encode_json({size => 500})),
		{search => {size => 500, index => "twitter"}},
		"POST with size <= 5000 ok"
	);

	test_json(
		GET("/twitter?size=6000"),
		{code => 416, message => "size parameter exceeds maximum of 5000" },
		"GET with size > 5000 fails"
	);

	test_json(
		POST("/twitter", Content => encode_json({size => 6000})),
		{code => 416, message => "size parameter exceeds maximum of 5000" },
		"POST with size > 5000 fails"
	);
}

done_testing;