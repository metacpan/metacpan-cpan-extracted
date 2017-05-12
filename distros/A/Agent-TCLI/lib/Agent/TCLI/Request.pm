package Agent::TCLI::Request;
#
# $Id: Request.pm 62 2007-05-03 15:55:17Z hacker $
#
=head1 NAME

Agent::TCLI::Request - A Request class for Agent::TCLI::Request.

=head1 SYNOPSIS

An object for storing Agent::TCLI::Request information. Used by Transports
and not externally accessible at this point.

=head1 OVERVIEW

Requests are the basic transaction in TCLI. In the simplest form, they are created by Control
for sending to the Command to perform the Request. Requests come with their own Respond
method that will generate a Response object, so that Commands do not need to implement that logic.

In the more complex form, Requests may be handled directly by Transports. Of course,
Transports do not process a Request, they merely move them. If a Transport if acting on a Request (or the Reponse)
it must have it's own logic for doing so. In order to facilitate this process, sender and postback attrbutes
are arrays, so that they may be stacked. The Respond method will remove the entries from the stack.

=cut

use warnings;
use strict;
#use Carp;

use Object::InsideOut qw(Agent::TCLI::Base);
use Agent::TCLI::Response;

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: Request.pm 62 2007-05-03 15:55:17Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes may be accessed through a combined mutator.
If the attribute is an array type, then additional array mutators are
available and described below.
In addition, Agent::TCLI::Request suports Auto-Attributes as described below.

=over

=item id

Id for request tracking. Must be unique for each request. One should
probably just let the object set it automatically.

=cut
my @id				:Field
					:All('id');

=item args

The request's arguments as parsed into an array. Usually built by the
Agent::TCLI::Control, but may be set up externally as well.
B<args> will only accept ARRAY type values. Since B<args> is an array, it is
often best use one of the mutator methods listed below.

=cut
my @args			:Field
					:All('args')
					:Type('ARRAY' );

=item command

An array containing the prmoinent verb for this request, followed by the
rest of the context the command was issued in reversed.
B<command> will only accept ARRAY type values. Since B<command> is an array,
it is often best use one of the mutator methods listed below.

=cut
my @command			:Field
					:All('command')
					:Type('ARRAY' );

=item sender

The POE session making the request, so that the response can be returned
properly. It is also the Tranport used when going between agents.

=cut
my @sender			:Field
					:All('sender')
					:Type('ARRAY' );

=item postback

The event to post the response back to. It is also the return addressee when
going between agents.

=cut
my @postback		:Field
					:All('postback')
					:Type('ARRAY' );

=item input

The exact, unparsed input string from the user. This might be useful for
some commands, but mostly is ignored. If not provided it should be automatically
generated from the command and args if necessary.

=cut
my @input			:Field
					:All('input');

=item response_count

A counter that is incremented for every response to this request.
This is updated automatically through the use of the Respond method.
B<response_count> will only accept NUMERIC type values.

=cut
my @response_count	:Field  :All('response_count')
					:Type('NUMERIC' );

=item response_verbose

A setting that determines how much of the request information
is returned with the response. If true, the entire request
will be returned. If false, only the required fields will be.
B<response_verbose> should only contain boolean values.

=cut
my @response_verbose	:Field
#					:Type('boolean')
					:All('response_verbose');

=item Arrays

Attributes that are typed as arrays also support the following mutators for
the lazy:
B<shift_&gt;field&lt;> - works the same as I<shift>, returing the shifted member.
B<unshift_&gt;field&lt;(list)> - works the same as I<unshift>.
B<pop_&gt;field&lt;> - works the same as I<pop>, returing the popped member.
B<push_&gt;field&lt;(list)> - works the same as I<push>.
B<depth_&gt;field&lt;> - returns the curent size of the array.

=item Auto-Attributes

Agent::TCLI::Request has an AutoMethod routine that can create object attributes
on the fly. These all use lower case set_/get_ mutators which differentiates
them from the pre-defined attributes. Since all responses should contain the
original Request object, this is a handy way to pass stateful information
about the Request to the postback handling the response.

For example: $request->set_test('like');

If the new attribute name contains 'array', it is created as an array type
and the array mutators listed above will apply.

=back

=cut

sub _init :Init {
	my ($self, $args) = @_;

	# Gee, this will make it real easy to 'break' into the request object
	# from outside by knowing the ID. That's OK. Nothing to hide here.


	$self->set(\@id, ( defined($args->{'id'}) && $args->{'id'} )
		? $args->{'id'}
		: $$self ) unless ($self->id);
}

=head2 METHODS

=over

=item MakeResponse ( <text>, <code> )

MakeResponse used internally by Respond to create the Response object
to send back to the requestor. The only reason to call MakeResponse
directly would be to add or remove attributes before the Response is
sent.

=cut

sub MakeResponse {
	my ($self, $txt, $code) = @_;

	# TODO better validation of code
	$code = 200 unless defined($code);

	my $response = Agent::TCLI::Response->new(
		'body'		=> $txt,
		'code'		=> $code,
		'id'		=> $self->id,
		'sender'	=> [@{$self->sender}],
		'postback'	=> [@{$self->postback}],
		'response_count'=>$self->response_count,
	);

	if ( $self->response_verbose )
	{
		$response->args($self->args);
		$response->input($self->input);
		$response->command($self->command);
		$response->response_verbose($self->response_verbose);

		# copy all the dynamically created fields
		$self->Verbose("MakeResponse: can",4, \@{$self->can} );
		foreach my $field ( @{ $self->can } )
		{
			if ( $field =~ s/^get_// )
			{
				my $acc = 'get_'.$field;
				my $mut = 'set_'.$field;
				$response->$mut( $self->$acc ) if (defined( $self->$acc ));
			}
		}
	}

	return $response;
}

=item Respond ( <poe_kernel>, <text> [, <code>]) or ( <poe_kernel>, <response obj> )

Respond is the proper way to return a response to a request. It requires a
reference to the poe_kernel as the first parameter. The second parameter
may be either some text for the response or a Response object. The third
parameter is the resposne code. If not provided, it defaults to 200. While not
required, it is best to always fill in the response code. The response code
will be ignored if a Response object is provided.

=cut

sub Respond {
	# using Respond to return anything. That way it will
	# be easier to change/override how to return later on,
	# and call from the middle of a method.
	my ($self, $kernel, $txt, $code) = @_;
	$self->Verbose("Respond: id(".$id[$$self].") dump(".$self->dump(1),5);

	if ( ref($kernel) !~ /Kernel/i  )
	{
		$self->Verbose("Respond needs kernel as first parameter",0,$kernel);
		die;
	}

	$response_count[$$self]++;

	my $response;
	if ( ref($txt) =~ /Response/ )
	{
		$response = $txt;
	}
	else
	{
		$response = $self->MakeResponse( $txt, $code);
	}

	# If we have a control, then we really need to post to it's id.
	# I could stringify control to avoid this, but that seems rather inobvious
	# and I'd probably create some bug somewhere else that would be horrific
	# to debug because of it.

	# TODO. Can't do multple replies like this.
	my $sender = $self->sender->[0];
	my $postback = $self->postback->[0];
	if ( ref($sender) =~ /Control/ )
	{
		$self->Verbose("Respond: control(".$sender->id.") pb(".$postback.
			") txt($txt)",2);
		$sender = $sender->id()
	}
	else
	{
		$self->Verbose("Respond: sender(".$sender.") pb(".$postback.
			") txt($txt)",2);
	}

	$self->Verbose("Respond: id(".$id[$$self].") count(".$response_count[$$self].
		")  code(".$response->code.")",1) if defined($id[$$self]);
	$self->Verbose("Respond: sender(".$sender.") pb(".$postback.")");
	$kernel->call( $sender => $postback => $response );
}

# Standard class utils are inherited

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

The (ab)use of AUTOMETHODS is probably more a bug than a feature.

SHOULDS and MUSTS are currently not always enforced.

Test scripts not thorough enough.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
