#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More;

SKIP: {
	if ($^O eq 'MSWin32') {
		skip("No functions to override in Win32", 1);
	} else {
		require Crypt::URandom;
		my $initial_length = 20;
		my $initial_data = Crypt::URandom::urandom($initial_length);
		ok(length $initial_data == $initial_length, "Correct number of bytes returned before fork:$initial_length");
		if (my $pid = fork) {
			my $parent_length = 30;
			my $parent_data = Crypt::URandom::urandom($parent_length);
			ok(length $parent_data == $parent_length, "Correct number of bytes returned in parent after fork:$parent_length");
			waitpid $pid, 0;
			ok($? == 0, "Correct number of bytes returned in child after fork");
		} elsif (defined $pid) {
			my $child_length = 15;
			my $child_data = Crypt::URandom::urandom($child_length);
			if (length $child_data == $child_length) {
				exit 0;
			} else {
				exit 1;
			}
		} else {
			die "Failed to fork:$!";
		}
		my $post_length = 20;
		my $post_data = Crypt::URandom::urandom($post_length);
		ok(length $post_data == $post_length, "Correct number of bytes returned after fork:$post_length");
	}
}
done_testing();
