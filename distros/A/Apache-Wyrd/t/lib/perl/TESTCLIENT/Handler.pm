#!/usr/bin/perl -w

package TESTCLIENT::Handler;
use strict;
use base qw(Apache::Wyrd::Interfaces::GetUser Apache::Wyrd::Handler);

sub init {
	my $self = shift;
	return {
		debug		=>	5,
		error_page	=>	0,
		req			=> $self->{'req'}
	};
}

sub process {
	my ($self) =@_;
	#get user with the Apache::Wyrd::Interfaces::GetUser method 'user'
	$self->{init}->{user} = $self->user('TESTCLIENT::User');
	return;
}

1;