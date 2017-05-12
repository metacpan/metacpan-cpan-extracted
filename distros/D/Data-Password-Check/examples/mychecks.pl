#!/usr/bin/perl
use strict;
use warnings;

use MyPassword;

my $pwcheck = MyPassword->check(
	{
		'password'	=> 'more_than_just_x',
		# run the new test(s) we've written
		'tests'		=> [ 'all_x' ],
	}
);

# did we have any errors?
if ($pwcheck->has_errors) {
	# print the errors
	print(
		join("\n", @{ $pwcheck->error_list }),
		"\n"
	);
}

