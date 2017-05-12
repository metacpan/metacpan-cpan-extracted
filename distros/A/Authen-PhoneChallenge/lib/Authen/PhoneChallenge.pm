package Authen::PhoneChallenge;
use warnings;
use strict;
use Carp;
use XML::Simple;

our $VERSION = "0.02";

=head1 NAME

PhoneChallenge - Module that does simple challenge/response using only numbers, for use in phone systems.

=head1 DESCRIPTION

This module is a simple challenge/response system for use over the phone.
The scheme is that a user is issued a list of indexes and values.  When they
need to authenticate the system prompts them with an index and they respond with
the associated value.


=head1 SYNOPSIS

use Authen::PhoneChallenge;
my $auth = new Authen::PhoneChallenge($authFile);
$auth->set_user($userId);
$auth->get_challenge();
...
$auth->check_response($resp);


=head1 FILE FORMAT

The authentication file is a simple XML document in the following format:

<users>
	<user id="1234">
		<token challenge="1" response="1234" used="0"/>
		<token challenge="2" response="3456" used="0"/>
	</user>
</users>

=head1 FUNCTIONS

=cut

=head2 new

Create a new challenge object.  Must pass a authentication file name (See FILE FORMAT above) 

=cut

sub new
{
	my $class = shift;
	my $self = {
		user		=> undef,
		authFile	=> shift,
		authData	=> undef,
		maxTokenUse	=> undef,
		challenge	=> undef,
	};

	return bless $self, $class;
}


=head2 set_user

Set the user ID for all future operations.

=cut

sub set_user
{
	my $self = shift;

	$self->{user} = shift || carp('Must pass user ID');
	
	# Load the data
	$self->parse_authen_file();

	return defined $self->{authData};
}

=head2 get_challenge

Get a challenge for the user.
Calling get_challenge will invalidate any outstanding challenges.

=cut

sub get_challenge
{
	my $self = shift;
	return unless defined $self->{authData};

	my @challenges = keys %{$self->{authData}};

	my $index = int(rand(@challenges));
	$self->{challenge} = $challenges[$index];

	return $self->{challenge};
}


=head2 check_response

Check a response for validity.

=cut

sub check_response
{
	my $self = shift;
	return unless defined $self->{authData} && defined $self->{challenge};

	my $resp = shift || croak('No response passed');

	if ($self->{authData}{$self->{challenge}}{response} eq $resp)
	{
		$self->{challenge} = undef;
		return 1;
	}

	return;
}


sub parse_authen_file
{
	my $self = shift;
	$self->{authData} = undef;

	return if(!-e $self->{authFile});

	my $parser = XML::Simple->new();
	my $doc = $parser->XMLin($self->{authFile});

	return if(!$doc->{user}{$self->{user}});

	foreach my $token (@{$doc->{user}{$self->{user}}{token}})
	{
		$self->{authData}{$token->{challenge}} = {
			response => $token->{response},
			used => $token->{used}
		};
	}
}

1;
__END__
=head1 DEPENDENCIES

XML::Simple

=head1 BUGS/CAVEATS

No know bugs at this time.  If you find one let me know.

BIG SCARY NOTE: This module IS NOT, and WILL NOT be as secure as a real challenge/response/OTP system (like OPIE).  It was
written only to be slightly more secure than a shared PIN number among users.

=head1 AUTHOR

Scott Peshak <speshak@randomscrews.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 Scott Peshak
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
