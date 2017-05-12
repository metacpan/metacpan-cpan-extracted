# $Id: Testee.pm 62 2007-05-03 15:55:17Z hacker $
package Agent::TCLI::Testee;

=pod

=head1 NAME

Agent::TCLI::Testee - Write Test scripts to control TCLI agents.

=head1 SYNOPSIS

	use Test::More qw(no_plan);
	use Agent::TCLI::Transport::Test;
	use Agent::TCLI::Testee;

	use_ok('Agent::TCLI::Package::Eliza');

	my $test1 = Agent::TCLI::Package::Eliza->new({
		});

	my $test_master = Agent::TCLI::Transport::Test->new({
    	'control_options'	=> {
		    'packages' 	=> [ $test1, ],
    	},
	});

	my $eliza = Agent::TCLI::Testee->new(
		'test_master'	=> $test_master,
		'addressee'		=> 'self',
	);

	$eliza->is_body( 'eliza','Context now: eliza', 'Start up eliza');
	$eliza->like_body( 'hello', qr(problem), 'eliza chat begins');
	$eliza->is_code( 'You are not really a therapist.',200, 'chat');
	$eliza->is_code( 'Do you have malpractice insurance?',200, 'chat');
	$eliza->like_body( '/exit',qr(Context now: ), "Exit ok");

=head1 DESCRIPTION

The Testee is the critical interface for writing test scripts in the TCLI
system. It allows one to write tests in the standard Test::Tutorial way
that makes a request of a TCLI agent (the testee) and expects a response. The tests
are coordinated by a test master who interfaces with other transports
to deliver the commands to one or more testee agents.

=head1 WRITING TESTS

Each test is written following the same basic pattern and is a method call
on a testee object. The see below for the test typess currently available.

There are currently two things in the response that can be tested, the B<body>
and the B<code>. The body is the textual response that a human receives from
the agent. The code is a HTTP::Status value that indicates the success or
failure of the request. Often is is simpler to test for a response code equal to
200 (OK) than to write a regex. Though sometimes a regex is required to know
that the response was actually what was desired.

The parameters for mosts tests are:

=over 4

=item * request - the text command to send to the testee

=item * expected - the response desired

=item * name - a name to identify the test in the output

=back

Thus the complete test looks like:

	$testee->is_code("status", 200,"status ok");

The ok and not_ok tests check if the response code falls within a range of
values indicating success or failure, repsectively. One does not need to supply
an expected response code value with these tests.

	$testee->ok("status","status ok");

There are times when a single request may elicit multiple responses. One can use
a blank request to add tests for additional responses to the prior request. One cannot
test both the code and the body on the same response. One can test the code of
the first response and the body of the second. All additional tests must
immediately follow the original populated request.

A request is not actually sent until a new request is made or a test_master
command like run or done is called.

When there are multiple responses per request, the tests will be executed
on the responses in the order that they are written in the script. However, the
test script is usually running asnchronously, and other responses to later
requests may be processed before all responses to earlier requests have arrived.

Currently each test requires a response. There is no mechanism that allows one
to write a test that pass if three to five responses with code 200 are
revceived. That is a desired future feature.

=head3 Greedy Tests

B<is_*> and B<like_*> tests are greedy by default. That is they use up and expect
a response for every test. Other tests (not yet available), such as
B<response_time> (coming soon) are not greedy and act on the next response
received while still allowing other tests to execute on the same response. It
might be useful to have no greedy versions of B<is_*> and B<like_*> but the
exact syntax to do so has not been worked out yet.

=head3 Response Codes

The response codes that come back in a response are modeled after HTTP Status
codes. For most cases, the ok / is_success and not_ok / is_error codes will
suffice for testing.

There are some existing packages, most notably
Agent::TCLI::Package::Tail, which have commands that may take a while to return
results after the command is accepted. These packages will return a 100
(Continue, or in SIP, Trying) to indicate that the request was received and
acted upon, but the result is not yet determined. One may explictly test for
a 100 response, but if one does not, it is silently ignored.

TCLI response codes will maintain compatibility
with HTTP::Status codes for the forseeable future. One may use HTTP::Status to
import its constants to provide clarity in test scripts, but that will not be
automatically done by Testee.

=head3 Request Id

Each request and the corresponding responses are tagged with an id that is
unique. Each of the tests below return the id for the request, though normally
one does not need to capture the id. The id is necessary to get parameters
from a response or get the full set of responses.

=head1 INTERFACE

=head2 ATTRIBUTES

These attrbiutes are used to set up the testee with new. Changing them
afterwords is allowed, but unsupported, and may be restricted in the future.

=cut

use warnings;
use strict;

use vars qw($VERSION @EXPORT %EXPORT_TAGS );

use Carp;

use POE;
use Agent::TCLI::User;
require Agent::TCLI::Request;
use Test::Builder::Module;

use Object::InsideOut qw( Agent::TCLI::Base );

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: Testee.pm 62 2007-05-03 15:55:17Z hacker $))[2];

=over

=item test_master

The Transport::Test object that will be coordinating the tests
B<test_master> will only contain Agent::TCLI::Transport::Test values.

=cut
my @test_master		:Field
					:Type('Agent::TCLI::Transport::Test')
					:All('test_master');

=item transport

The POE alias of the transport that will deliver the request. Typically
this is 'transport_I<protocol>' where I<protocol> is the lower case protocol
name.
B<transport> should only contain scalar values.

=cut
my @transport		:Field
#					:Type('scalar')
					:All('transport');
=item protocol

The protocol to use to deliver the request. The transport must be prepared
to handle this protocol.
B<protocol> should only contain scalar values.

=cut
my @protocol		:Field
#					:Type('scalar')
					:All('protocol');

=item addressee

The addressee of the reuqest in a format that the protocol can understand
B<addressee> should only contain scalar values.

=cut
my @addressee		:Field
#					:Type('scalar')
					:Arg('name'=>'addressee','default'=>'self')
					:Acc('addressee');

=item last_request

The last request id that was used.
B<last_request> will only contain scalar values.

=cut
my @last_request			:Field
#					:Type('scalar')
					:All('last_request');

# Standard class utils are inherited
=back

=head2 METHODS

=over

=item new

	Agent::TCLI::Testee->new({
		'test_master'	=> # A Agent::TCLI::Transport::Test object.
		'addressee'		=> # The name of the addressee
		'transport'		=> # The default POE Session alias
		'protocol'		=> # The protocol to use

		'verbose'		=> # A positive integer counter for verbosity
		'do_verbose'	=> # a sub to use for verbose output
	});

See the Attributes for more information on what each one does.
I<verbose> and I<do_verbose> are inherited from Agent::TCLI::Base;

=back

=head2 Test requests

Unlike L<Test::More>, the first parameter for all Testee tests is a
request to send the the testee. The value evaluate to the text command that
one wants to send the Testee. This command is exactly the same as one would
use in the command line interface. One may submit an empty request
to add an additional test to the prior request.

=head2 Test names

All test functions take a test_name argument exactly as described in Test::More.
It will default to the request input unless it is defined. To submit
a test with no name, explicitly use an empty string as the test_name.

=over

=item ok / is_success

  ok ( 'some request', <test_name> );

B<ok> makes a request of the testee and passes if the response
has a code indicating success. B<ok> is really just an alias for B<is_success>
and they can be used interchangably. If the test fails, the response body
will be output with the diagnostics.

=cut

sub is_success {
	my $self = shift;

	# Must sneak an extra param in there so do_test will check codes correctly
	$self->last_request(	$self->test_master->build_test($self, 'is_success-code',
		$_[0], 1, '', $_[1]) );

	return( $self->last_request );
}

*ok = \&is_success;

sub are_successes {
	my $self = shift;
	# Must sneak an extra param in there so do_test will check codes correctly
	$self->last_request(
		$self->test_master->build_test($self, 'are_success-code',
		$_[0], 1, '', $_[1])
	);
	return( $self->last_request);
}

=item not_ok / is_error

  not_ok ( 'some request', <test_name> );

B<not_ok> makes a request of the testee and passes if the response
has a code indicating failure. B<not_ok> is really just an alias for B<is_error>
and they can be used interchangably. If the test fails, the response body
will be output with the diagnostics.

=cut

sub is_error {
	my $self = shift;
	# Must sneak an extra param in there so do_test will check codes correctly
	$self->last_request(
		$self->test_master->build_test($self, 'is_error-code',
		$_[0], 1, '', $_[1])
	);
	return( $self->last_request);
}

*not_ok = \&is_error;

#=item do / is_trying
#
#  do ( 'some request', <timeout>, <test_name> );
#
#Some commands, such as setting a tail or watch, will not return response
#with content immediately. These may however return a response with a
#seies 100 code for Trying. B<do> makes a request of the testee and passes
#if a Trying response is received within the timeout in seconds.
#B<do> is really just an alias for B<is_trying>
#and they can be used interchangably. If the test fails, the response body
#will be output with the diagnostics.
#One must follow up with other tests if checking actual responses is necesary.
#
#
#=cut
# Need to fix do_test as well as check for other issues before enabling
#sub is_trying {
#	my $self = shift;
#	# Must sneak an extra param in there so do_test will check codes correctly
#	$self->last_request(
#		$self->test_master->build_test($self, 'is_trying-code',
#		$_[0], 1, '', $_[1])
#	);
#	return( $self->last_request);
#}
#
#*do = \&is_trying;


sub are_errors {
	my $self = shift;
	# Must sneak an extra param in there so do_test will check codes correctly
	$self->last_request(
		$self->test_master->build_test($self, 'are_error-code',
		$_[0], 1, '', $_[1])
	);
	return( $self->last_request);
}

=item is_body

  is_body ( 'some request', 'expected response', <test_name> );

is_body() makes a request of the testee and compares the response
with the expected response to see if the test passed or failed. As with
Test::More is, diagnostics will indicate what is received when the
test failed.

=cut

# All tests get passed the test, the command, value 1, value2, and the name.
# Currently value2 is unused, but will probably be enabled for compare tests soon.

sub is_body {
	my $self = shift;
	$self->last_request(
		$self->test_master->build_test($self, 'is_eq-body',
		$_[0], $_[1], '', $_[2] )
	);
	return( $self->last_request);
}

sub are_bodies {
	my $self = shift;
	$self->last_request(
		$self->test_master->build_test($self, 'are_eq-body',
		$_[0], $_[1], '', $_[2] )
	);
	return( $self->last_request);
}

=item is_code

  is_code ( 'some request', RESPONSE_CODE , <test_name> );

is_code() makes a request of the testee and compares the response code
with the expected response code numerically to see if the test passed
or failed. If failed, diagnostics will indcate both the failure in the
comparison, and the body of the response.

=cut

sub is_code {
	my $self = shift;
	$self->last_request(
		$self->test_master->build_test($self, 'is_num-code',
		$_[0], $_[1], '', $_[2] )
	);
	return( $self->last_request);
}

sub are_codes {
	my $self = shift;
	$self->last_request(
		$self->test_master->build_test($self, 'are_num-code',
		$_[0], $_[1], '', $_[2] )
	);
	return( $self->last_request);
}

=item like_body

$testee->like_body ( 'some request', qr(expected) , <test_name> );

like_body() makes a request of the testee and compares the response
with the supplied regular expression to see if the test passed or failed. As with
Test::More is, diagnostics will indicate what is received when the
test failed.

=cut

sub like_body {
	my $self = shift;
	$self->last_request(
		$self->test_master->build_test($self, 'like-body',
		$_[0], $_[1], '', $_[2] )
	);
	return( $self->last_request);
}

sub like_bodies {
	my $self = shift;
	$self->last_request(
		$self->test_master->build_test($self, 'are_like-body',
		$_[0], $_[1], '', $_[2] )
	);
	return( $self->last_request);
}

=item unlike_body

$testee->unlike_body ( 'some request', qr(expected) , <test_name> );

unlike_body() works as like_body above except it passes if response
does not match the regex.

=cut

sub unlike_body {
	my $self = shift;
	$self->last_request(
		$self->test_master->build_test($self, 'unlike-body',
		$_[0], $_[1], '', $_[2] )
	);
	return( $self->last_request);
}

sub unlike_bodies {
	my $self = shift;
	$self->last_request(
		$self->test_master->build_test($self, 'unlike-body',
		$_[0], $_[1], '', $_[2] )
	);
	return( $self->last_request);
}

=item like_code

  like_code ( 'some request', qr(CODE) , <test_name> );

like_code() makes a request of the testee and compares the response code
with the supplied regular expression to see if the test passed or failed.
Diagnostics are the same as is_code. As codes are numeric, this test is
not really effective and better ways of testing codes are planned. Given the
current way tests are built, it was easier to have this test than to exclude it.

=cut

sub like_code {
	my $self = shift;
	$self->last_request(
		$self->test_master->build_test($self, 'like-code',
		$_[0], $_[1], '', $_[2] )
	);
	return( $self->last_request);
}

sub like_codes {
	my $self = shift;
	$self->last_request(
		$self->test_master->build_test($self, 'are_like-code',
		$_[0], $_[1], '', $_[2] )
	);
	return( $self->last_request);
}

=item unlike_code

  unlike_code ( 'some request', qr(CODE) , <test_name> );

unlike_code() works as like_code above except it passes if response
does not match the regex.

=cut

sub unlike_code {
	my $self = shift;
	$self->last_request(
		$self->test_master->build_test($self, 'unlike-code',
		$_[0], $_[1], '', $_[2] )
	);
	return( $self->last_request);
}

sub unlike_codes {
	my $self = shift;
	$self->last_request(
		$self->test_master->build_test($self, 'are_unlike-code',
		$_[0], $_[1], '', $_[2] )
	);
	return( $self->last_request);
}

=item get_param ( <param>, [ <id>, <timeout> ] )

B<get_param> will parse the textual responses from a request and attempt
to extract a value. It requires a param argument that is the parameter
to try and obtain a value for. It takes an optional request id
from a prior request. If not supplied, it will use the last request made.
It also takes an optional timeout value, which will be passed to B<done_id>
to wait for all responses to that request to come in.

B<get_param> attempts to parse the text in the responses to find the value
for the parameter being requested. It expects that the response is
formatted appropriately to extract the parameter.
Valid formats to receive the parameter are:
	 param=something
	 param something
	 param="a quoted string with something"
	 param "a quoted string with something"
	 param: a string yaml-ish style, no comments, to the end of the line
	 param: "a quoted string, just what's in quotes"
It returns the value of the parameter requested, or undefined if it
cannot be found.

=cut

sub get_param {
	my ($self, $param, $id, $timeout) = @_;

	$id = $self->last_request->id  unless  ( defined($id) && $id );

	return(
		$self->test_master->get_param(
		$param, $id, $timeout )
	);
}

=item get_responses ( [ <id>, <timeout> ] )

B<get_responses> will retrieve textual responses for a request.
It takes an optional request id from a prior request. If not
supplied, it will use the last request made. It also takes an optional
timeout value.
It returns the text from all available responses, each separated by a pair
of newlines.
Calling <get_responses> forces the completion of all outstanding tests for that
request. That is, the tests will fail if no-reponses have been received
before the timeout is reached.

=cut

sub get_responses {
	my ($self, $id, $timeout) = @_;

	$id = $self->last_request->id  unless ( defined($id) && $id );

	return(
		$self->test_master->get_responses(
		$id, $timeout )
	);
}

sub _preinit :PreInit {
	my ($self,$args) = @_;

	$args->{'do_verbose'} = sub { diag( @_ ) } unless defined($args->{'do_verbose'});

}


sub _init :Init {
	my ($self, $args) = @_;

	$self->test_master->load_testee($self);
}

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

There is no separation between users running tests, which means it
could be very ugly to have multiple users try to run tests on one TCLI Agent.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
