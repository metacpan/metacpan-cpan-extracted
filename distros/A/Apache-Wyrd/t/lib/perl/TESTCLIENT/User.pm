#!/usr/bin/perl -w


package TESTCLIENT::User;
use strict;
use base qw(Apache::Wyrd::User);
use Apache::Wyrd::Services::SAK qw(token_parse);

1;

my %passwords = (
	'testuser'	=>	'testing123'
);

my %auth_level = (
	'testuser'		=>	{
		'test' => 1,
		'admin'	=> 0
	}
);

sub get_authorization {
	my $self = shift;
	unless ($passwords{$self->{username}} eq $self->{password}) {
		$self->auth_error('Invalid Username or Password.');
		return;
	}
	$self->{auth} = $auth_level{$self->{username}};
}

sub auth {
	my ($self, $levels) = @_;
	return 1 if ($self->{'auth'}->{'all'});
	my @levels = token_parse($levels);
	foreach my $level (@levels) {
		return 1 if ($self->{'auth'}->{$level});
	}
	return;
}
