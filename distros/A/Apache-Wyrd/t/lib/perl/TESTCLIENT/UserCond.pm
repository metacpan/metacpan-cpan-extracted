#!/usr/bin/perl -w


package TESTCLIENT::UserCond;
use strict;
use base qw(TESTCLIENT::Wyrd);

sub _format_output {
	my ($self) = @_;
	my $user = $self->dbl->user;
	my $auth = $self->{'auth'};
	my $username = $self->{'user'};
	$self->_debug("User is " . $user->username . " and auth is " . $user->auth($auth));
	my $failed = undef;
	if ($username) {
		$failed = 1 unless (lc($user->username) eq lc($username));
	} elsif ($auth) {
		$failed = 1 unless ($user->auth($auth));
	} else {
		$failed = 1;
	}
	$self->_data(undef) if $failed;
	return;
}

1;