package Agent::TCLI::User;
#
# $Id: User.pm 59 2007-04-30 11:24:24Z hacker $
#
=head1 NAME

Net::CLI::User - A User class for Net::CLI.

=head1 SYNOPSIS

An object for storing Net::CLI user information.

	my $user = Net::CLI::User->new(
		'id'		=> 'user@example.com',
		'protocol'	=> 'jabber',
		'auth'		=> 'read only',
	);

	my $name = $user->get_name;

	print "My user is ".$name.". \n";
	print $name."'s domain is ".$user->get_domain.". \n";


=cut

use warnings;
use strict;
#use Carp;

use Object::InsideOut qw(Agent::TCLI::Base);
use Params::Validate qw(validate_with);

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: User.pm 59 2007-04-30 11:24:24Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard accessor/mutator
methods and may be set as a parameter to new unless otherwise noted.

=over

=item id

ID of user in a form acceptable to the protocol.
XMPP/Jabber IDs MUST not include resource information.

=cut
my @id		:Field	:All('id');

=item protocol

Protocol that user is allowed access on. Currently only xmpp and xmpp-groupchat
are supported by Transport::XMPP. If the protocol is xmpp-groupchat, the
Transport will automatically join the conference room at start-up.

=cut
my @protocol	:Field	:All('protocol');

=item auth

Authorization level of user. MUST be one of these values:
  B<reader> has read access
  B<writer> has write access
  B<master> has root access
  B<logger> receives copies of all messages, can't do anything

Note that commands must choose from the above to determine if a user can
do anything. Not very robust, but hey, it's not even 1.0 yet.

Every user should be defined with an B<auth>, but currently this is not
being checked anywhere.

=cut
my @auth 	:Field	:All('auth');

=item password

A password for the user.

For a private XMPP chatroom, this is used to log on. It is not used anywhere
else currently.

=cut
my @password		:Field
					:All('password');

# RemindHacker: I wrote a Eclipse Perl template csxattr for new attributes.

# Standard class utils are inherited

=back

=head2 METHODS

=head2 new (lots of stuff)

Creates a new user object. All the above attributes may be specified. Currently
all are optional, but it would be rather useless to have a user without an id or
protocol and auth is strongly recommended.

=over

=item get_name()

Retrieve the short name for the user. Currently anything in front of the '@'.

=cut

sub get_name {
  my $self = shift;
  my $id = $id[$$self];
  return ( $self->_set_err( { 'method' => 'get_name',
          'rebuke' => 'name not found in user id'} )
         ) unless ( $id =~ /(\w+)@([-\w]+)/ );
  return ($1);
} # End get_name

=item get_domain()

Retrieve the domain for the user. Currently whatever is after the '@'.

=cut

sub get_domain {
  my $self = shift;
  my $id = $id[$$self];
  return ( $self->_set_err( { 'method' => 'get_domain',
          'rebuke' => 'Domain not found in user id'} )
         ) unless ( $id =~ /(\w+)@([-.\w]+)/ );
  return ($2);
} # End get_domain

=item not_authorized ( { parameters (see usage) } )

Returns 0 if user is authorized, 'Not found' if user is not a match, and a message
if a match, but the protocol and/or auth do not match.

Checks id and optional parameters and returns false if matched. This method
will automatically strip off Jabber resource before matching user. It is
usually used as a passthrough while looping through an array/hash of
users in some other object.

It has optional parameters protocol and auth which must be supplied as
regular expression. The default is to use a regexp of any, which means
that the value must be defined in the user in order to match.

By returning false for authorization, one can check the reason why
a true value was returned for unauthorized, or just ignore it.

Usage:

	not_authorized ( { id	   =>  value,        # user id. Will strip off resource
					  protocol =>  qr(jabber),   # optional regex for protocol
					  auth	   =>  qr(master|writer),   # option regex for auth
					} );

=cut

sub not_authorized {
	my $self = shift;

	# Check if incorrect args are sent and set defaults for optionals
	my $args_ref = validate_with ( params => \@_,
		spec   => {
			id        => {     type => &Params::Validate::SCALAR },
			protocol  =>
			{	optional  => 1, default => qr(.*),        # default .* means any, simplifies matching if not set
				callbacks =>
				{ 'is a valid regex' => sub { ref ( $_[0] ) eq 'Regexp' } }
			},
			auth      =>
			{	optional  => 1, default => qr(.*),        # default .* means any, simplifies matching if not set
				callbacks =>
				{ 'is a valid regex' => sub { ref ( $_[0] ) eq 'Regexp' } }
			},
		},
	#	on_fail => sub { $self->_set_err( { 'method' => 'not_authorized',
	#                                       'rebuke' => shift } )
	#	},
	);

	# strip off /.* - jabber resource or something like it if there
	$args_ref->{'id'} =~ s|/.*||;

	# Not using OIO lvalues.
	my $protocol = $protocol[$$self];
	my $auth = $auth[$$self];

	my $txt = '';
	if ( $id[$$self] =~ /$args_ref->{'id'}/i )
	{
		# Match regex to pass. The default of any will pass if not specified.
		if ( $protocol !~ /$args_ref->{'protocol'}/ )
		{
			$txt .= "Improper protocol. $protocol !~ ".$args_ref->{'protocol'}.". \n";
		}
		if ( $auth !~ /$args_ref->{'auth'}/ )
		{
			$txt .= "Inadequate authorization. $auth !~ ".$args_ref->{'auth'}.". \n";
		}
	}
	else
	{
		$txt = "This is not me.";
	}

	$self->Verbose("not_authorized: for ".$args_ref->{'id'}." returning '".$txt."'");
	return $txt;

} # End not_authorized

1;
#__END__
=back

=head3 INHERITED METHODS

This module is an Object::InsideOut object that inherits from Agent::TCLI::Base. It
inherits methods from both. Please refer to their documentation for more
details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

SHOULDS and MUSTS are currently not always enforced.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

