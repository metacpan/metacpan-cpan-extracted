# $Id: Test.pm 62 2007-05-03 15:55:17Z hacker $
package Agent::TCLI::Transport::Test;

=pod

=head1 NAME

Agent::TCLI::Transport::Test - transport for testing commands

=head1 SYNOPSIS

	use Test::More qw(no_plan);
	ues Agent::TCLI::Transport::Test;
	use Agent::TCLI::Package::Tail;

	# set the list of packages
	my @packages = (
		Agent::TCLI::Package::Tail->new({
			'verbose'		=> \$verbose,
			'do_verbose'	=> sub { diag( @_ ) },
		}),
	);


	my $test_master = Agent::TCLI::Transport::Test->new({
	    'verbose'   	=> \$verbose,        # Verbose sets level

	    # change verbose output to Test::More::diag
		'do_verbose'	=> sub { diag( @_ ) },

		# load up the packages to support testing
	    'control_options'	=> {
		    'packages' 		=> \@packages,
	    },
	});

	# need at least one testee

	# Set up the local test
	my $target = Agent::TCLI::Testee->new(
		'test_master'	=> $test_master,
		'addressee'		=> 'self',
	);

=head1 DESCRIPTION

The Agent::TCLI::Transport::Test module is a bridge between the rest of the TCLI
system and Perl's TAP based testing system. This module uses Test::Builder
underneath and should be compatible with all other Test modules that use
Test::Builder.

The one cautionary note is that Agent::TCLI::Transport::Test runs on top of POE
which is an asynchronous, event based system. Typically, tests will not
complete in the order that they are written. There are various means to
establish control over the completion of prior tests which should be
sufficient for most cases. However, one should not write a test script
without some thought to the ordering needs of the tests and whether extra
tests need to be in place to ensure those needs are met.

=head1 GETTING STARTED

If you are unfamiliar with Perl's Test:: modules, then please see
L<Test::Tutorial> for background information.

One may look at some of the test scripts with the TCLI source for examples,
but they are limited to a single agent.
The TCLI core does not come with modules that are useful for multi-agent test
scripts. This is to reduce the dependencies for the Core. Please see example
scripts provided with other TCLI packages for better multi agent examples.

Currently, Agent::TCLI::Transport::Test offers only an object interface, so we're
using Test::More to set the plan and import diag() into the test script.
This might change at some point, but this kludge will always work.

As in the Synopsis, one will most often want to define the necesary packages
outside of the transport(s) used. Typically one will want the same packages
loaded in all the transports. By same, we mean the same package object
instantiations.

One then needs to create the Agent::TCLI::Transport::Test object. The Synoposis covers
the typical parameters set on creation. All of the Agent::TCLI::Transport::Test
class mutator methods are available within new, but generally should not be used.
There may be other inherited mutator methods from Agent::TCLI::Transport::Base that
could be useful.

Unlike other Transports, users do not have to be defined
for Transport::Test, as it will load a default user. Local tests are
executed with a Control created for the first user in the stack. Currently,
running with users other than the default has not been tested.

Then one needs to create at least one Agent::TCLI::Testee. The testee
object will be used for the actual tests. See Agent::TCLI::Testee
for the tests available.

Within the actual tests, the Agent::TCLI::Transport::Test (as test_master) offers two
flow/control commands. B<run> is necesary at the end of the tests to start
POE completely and finish the tests. B<done> may be used within the script
to force check for completion of all prior tests. B<done> is a test itself and
will report a success or failure.

=head2 ATTRIBUTES

Unless otherwise indicated, these attrbiute methods are for internal use. They are not
yet restricted because the author does not beleive his imagination is better
than the rest of collective world's. If there are use cases for accessing
the internals, please make the author aware. In the future, they may be
restricted to reduce the need for error checking and for security.

=over

=cut

use warnings;
use strict;

use vars qw($VERSION @EXPORT %EXPORT_TAGS );

use Carp;
#use Time::HiRes qw(time);

use POE;
use Agent::TCLI::Control;
use Agent::TCLI::Request;
use Agent::TCLI::User;
require Agent::TCLI::Transport::Base;

use Test::Builder::Module;

use Object::InsideOut qw( Agent::TCLI::Transport::Base Test::Builder::Module);

our $VERSION = '0.031.'.sprintf "%04d", (qw($Id: Test.pm 62 2007-05-03 15:55:17Z hacker $))[2];

#func#our $TCLI_TEST = Agent::TCLI::Transport::Test->new;

#func#BEGIN {
#func#	@EXPORT = qw( load_packages
#func#		is_body like_body
#func#		is_code like_code
#func#		);
#func#}

=item testees

An array of the testees that the test transport will be working with.

=cut

my @testees			:Field
					:All('testees')
					:Type('Array');

=item requests

An internal array acting as a queue of the requests to send. Requests are not
retained in the queue, but are only held until dispatched.

=cut
my @requests		:Field
					:All('requests')
					:Type('Array');

=item test_count

A running count of all the tests. Some requests may contain multiple tests.
B<test_count> will only contain numeric values.

=cut
my @test_count		:Field
					:Type('numeric')
					:All('test_count');

=item request_count

A counter for making request ids
B<request_count> will only contain numeric values.

=cut
my @request_count	:Field
					:Type('numeric')
					:All('request_count');

=item default_request

Normally a Agent::TCLI::Request object must be created for each test. This is the
default Request to use in making requests for each test. This may be set
by the user if the default is not approprate.
B<default_request> will only accept Agent::TCLI::Request type values.

=cut
my @default_request	:Field
					:All('default_request')
					:Type('Agent::TCLI::Request' );

=item requests_sent

Number of requests sent out.
B<requests_sent> will only accept Numeric type values.

=cut

my @requests_sent	:Field
					:All('requests_sent')
					:Type('Numeric');

=item requests_complete

Number of requests_completed
B<requests_complete> will only accept Numeric type values.

=cut
my @requests_complete	:Field
						:All('requests_complete')
						:Type('Numeric');

=item request_tests

A hash keyed by request ID of arrays of tests to perform on the responses
B<request_tests> will only contain hash values.

=cut
my @request_tests	:Field
					:Type('hash')
					:Arg('name'=>'request_tests', 'default'=> { } )
					:Acc('request_tests');

=item responses

A hash keyed on request_id to hold responses when multiple responses per request are expected.
B<responses> will only contain hash values.

=cut
my @responses		:Field
					:Type('hash')
					:Arg('name'=>'responses', 'default'=> { } )
					:Acc('responses');

=item responses_max_contiguous

This field hold a numeric value corellating to the response ID of the
maximum response received that had at least one response received
for all previous requests.
B<responses_max contiguous> will only contain numeric values.

=cut
my @responses_max_contiguous	:Field
					:Type('numeric')
					:Arg('name'=>'responses_max_contiguous', 'default'=> 1)
					:Acc('responses_max_contiguous');


=item dispatch_counter

A running counter of Dispatch attempts to prevent stalling.
B<dispatch_counter> will only contain numeric values.

=cut
my @dispatch_counter			:Field
					:Type('numeric')
					:All('dispatch_counter');

=item dispatch_retries

The number of times to retry the dispatching of queued requests. Increments are in 5 second blocks. Default is 6 or 30 seconds. This is a user adjustable setting.
When the count is reached, the next test is dispatched without regard to the state of the previous test.
The timeout will not start until dispatching is done or exceeded its retries. This allows for other requests to complete.
B<dispatch_retries> will only contain numeric values.

=cut
my @dispatch_retries			:Field
					:Type('numeric')
					:Arg('name'=>'dispatch_retries','default'=>6)
					:Acc('dispatch_retries');


=item timeout_counter

A running counter for timing out all requests.
B<timeout_counter> will only contain numeric values.

=cut
my @timeout_counter			:Field
					:Type('numeric')
					:All('timeout_counter');

=item timeout_retries

The number of times to retry the timeout. Increments are in 5 second blocks. Default is 6 or 30 seconds.
Timeout checks periodically to make sure we're still running requests. It begins the countdown when
all requests have been dispatched, so that we don't wait forever for something to complete. This is user adjustable.
B<timeout_retries> will only contain numeric values.

=cut
my @timeout_retries	:Field
					:Type('numeric')
					:Arg('name'=>'timeout_retries','default'=>6)
					:Acc('timeout_retries');

=item timeout_id

The id of the timeout event so that it can be rescheduled if necessary.

=cut
my @timeout_id		:Field
#					:Type('type')
					:All('timeout_id');

=item running

A flag to indicate if we've started the POE kernel fully, rather than just running slices.
This is set when B<run> is called.
B<running> should only contain boolean values.

=cut
my @running			:Field
#					:Type('boolean')
					:Arg('name'=>'running','default'=>0)
					:Acc('running');

=item last_testee

Internally used when building a new test to check what the last testee was.
B<last_testee> will only contain scalar values.

=cut
my @last_testee		:Field
#					:Type('scalar')
					:Arg('name'=>'last_testee','default'=>'')
					:Acc('last_testee');

=item dispatch_id

Holds the POE event ID for the Dispatch so it can be rescheduled.
B<dispatch_id> should only contain scalar values.

=cut
my @dispatch_id			:Field
#					:Type('scalar')
					:All('dispatch_id');

# Standard class utils are inherited

=back

=head2 METHODS

Most of these methods are for internal use within the TCLI system and may
be of interest only to developers trying to enhance TCLI.

The first three are the exception.

=over

=item done( <timeout>, <name> )

When B<done> is called, it will attempt to complete all previous requests before
continuing. If done is provided a name parameter, it will report its
results as a test. That is, it will pass if all previous tests are
completed before the timeout. In either case, it will return true if all tests
are complete and false otherwise.

It takes an optional timeout parameter, an integer in seconds. The default timeout
is 31 seconds if none is supplied.

It takes an option parameter of a test name.

=cut

sub done {
	my ($self, $wait, $name) = @_;

	$wait = 31 unless defined $wait;
	my $start = time();
	my $ready = 0;
	$self->Verbose($self->alias.":done: start($start) wait($wait)");

	# Clean out anything in kernel queue
#	$poe_kernel->run_one_timeslice unless ($self->running || $wait == 0 );

	# Try to finish up anything left out there.
	while ( $start + $wait > time() )
	{
		$self->Verbose($self->alias.":done: end(".($start + $wait).")time(".time().")  ",3);
		# make sure there is nothing in request queue
		$self->dispatch;
		$ready = $self->post_it('done');
		# Clean out anything in kernel queue
		$poe_kernel->run_one_timeslice;
		last if $ready;
		next;
	}

	$ready = $self->post_it('done') if ($wait == 0);

	if  ( (not $ready && $wait == 0 )  ||
		($ready && $wait > 0 ) )
	{
		$self->Verbose($self->alias.":done: ".
			" run(".$self->running.")  dc(".$dispatch_counter[$$self].") dr(".
			$dispatch_retries[$$self].") tc(".$timeout_counter[$$self].") tr(".
			$timeout_retries[$$self].") requests(".$self->depth_requests.") ");
		$self->Verbose($self->alias.":done: count(".$request_count[$$self].
			") contiguous(".$self->responses_max_contiguous.")");
	}

	# there may be tests left in request_tests.
	# Some will be all type tests (ares...), which do not matter.
	# but some will need to be failed.

	my $test;

	ID: foreach my $id ( sort keys %{$self->request_tests} )
	{
		# are there more tests left for this request?
		next ID unless ( scalar(@{$self->request_tests->{ $id } } ) > 0);

		TEST: while ( @{ $self->request_tests->{ $id } } )
		{
			$test = shift @{ $self->request_tests->{ $id } };
			# if this is an multi response test, then skip it
			if ( $test->[0] =~ qr(are) )
			{
				next TEST;
			}

			# any other test must fail if there is no response

			$self->builder->ok( 0, $test->[3] );
			$self->builder->diag("Response not recieved for this test's request.");

		}

	}

	if ( defined($name) && $name ne '' )
	{
		$test_count[$$self]++;
		$self->builder->ok( $ready, $name );
	}
	$self->Verbose($self->alias.":done: ready($ready) ");

	return ($ready);
}

=item done_id(<id>, <timeout>, <name> )

B<done_id> works similarly to B<done> except that it waits only for the
results from one request, as specified by the id. If a request id is not
supplied, it will default to the last request made.

It takes an optional timeout parameter, an integer in seconds. The default timeout
is 31 seconds if none is supplied.

It takes an option parameter of a test name.

=cut

sub done_id {
	my ($self, $id, $wait, $name) = @_;

	$wait = 31 unless defined $wait;
	my $start = time();
	my $ready = 0;

	# validate id
	unless ( defined($id) && $id )
	{
		# Use last id if not supplied
		$id = $self->make_id( $request_count[$$self] );
	}

	$self->Verbose($self->alias.":done_id: id($id) start($start) wait($wait)",1);

	# Clean out anything in kernel queue
#	$poe_kernel->run_one_timeslice unless ($self->running || $wait == 0 );

	# Try to finish up anything left out there.
	while ( $start + $wait > time() )
	{
		$self->Verbose($self->alias.":done_id: end(".($start + $wait).") time(".time().")  ",3);
		# make sure there is nothing in request queue
		$self->dispatch;
		$ready = $self->post_it('done');
		# Clean out anything in kernel queue
		$poe_kernel->run_one_timeslice;
		last if $ready;
		next;
	}

	$ready = $self->post_it('done') if ($wait == 0);

	if  ( (not $ready && $wait == 0 )  ||
		($ready && $wait > 0 ) )
	{
		$self->Verbose($self->alias.":done: ".
			" run(".$self->running.")  dc(".$dispatch_counter[$$self].") dr(".
			$dispatch_retries[$$self].") tc(".$timeout_counter[$$self].") tr(".
			$timeout_retries[$$self].") requests(".$self->depth_requests.") ");
		$self->Verbose($self->alias.":done: count(".$request_count[$$self].
			") contiguous(".$self->responses_max_contiguous.")");
	}

	# there may be tests left in request_tests.
	# Some will be all type tests (ares...), which do not matter.
	# but some will need to be failed.

	my $test;

	TEST: while ( @{ $self->request_tests->{ $id } } )
	{
		$test = shift @{ $self->request_tests->{ $id } };
		# if this is an multi response test, then skip it
		if ( $test->[0] =~ qr(are) )
		{
			next TEST;
		}

		# any other test must fail if there is no response

		$self->builder->ok( 0, $test->[3] );
		$self->builder->diag("Response not recieved for this test's request.");

	}

	if ( defined($name) && $name ne '' )
	{
		$test_count[$$self]++;
		$self->builder->ok( $ready, $name );
	}
	$self->Verbose($self->alias.":done: ready($ready) ");

	return ($ready);
}


=item load_testee ( <testee> )

The preferred way to load a testee is to set 'test_master' when the testee is
created. Testee will then call this function on initializtion. A testee is
an Agent::TCLI::Testee object.

=cut

sub load_testee {
	my ($self, $testee) = @_;
#func#	my $self = ( ref $_[0] && (ref $_[0]) =~ /Agent::TCLI::.*TEST/ )
#func#		? shift : $TCLI_TEST;
	$self->Verbose($self->alias.":load_testee: dump ".$testee->dump(1),3);

	$self->push_testees($testee);
}

=item run

B<run> is called at the end of the test script. It will call POE::Kernel->run
to finish off all of the requests. Other POE event handlers will ensure that all
queued requests are dispatched and all requests dispatched are completed.

Running does not take any parameters and does not return anything.

=cut

sub run {
	my $self = shift;
	$self->Verbose($self->alias.":run: running (".$self->depth_requests.") requests " );

	# requests still left in queue (How could there not be?)
	if ( $self->depth_requests > 0 )
	{
		# Whatever's left in the queue is bigger than us little synchronous
		# calls. Send it over to the big Dispatch.
		$poe_kernel->post($self->alias, 'Dispatch', 1 );
	}

	# set running state for Timeout.
	$self->running(1);

	$poe_kernel->run;
}

=item preinit

This private Object::InsideOut (OIO) method is used for object initialization.

=cut

sub _preinit :PreInit {
	my ($self,$args) = @_;

	$args->{'alias'} = 'transport_test' unless defined( $args->{'alias'} ) ;

  	$args->{'session'} = POE::Session->create(
        object_states => [
        	$self => [ qw(
	            _start
            	_stop
        	    _shutdown
        	    _child
        	    _default

				Dispatch
        	    SendChangeContext
        	    SendRequest

				PostResponse
        	    Timeout
        	)],
        ],
  	);

	$args->{'peers'} = [ Agent::TCLI::User->new({
		'id'		=> 'test-master@localhost',
		'protocol'	=> 'test',
		'auth'		=> 'master',
	})] unless defined($args->{'peers'});

	$args->{'do_verbose'} = sub { diag( @_ ) } unless defined($args->{'do_verbose'});

}

=item _init

This private OIO method is used for object initialization.

=cut

sub _init :Init {
	my ($self, $args) = @_;

	$self->set(\@default_request, Agent::TCLI::Request->new({
		'id'		=> 1,
#		'args'		=> ,
#		'command'	=> ,
		'sender'	=> [$self->alias],
		'postback'	=> ['PostResponse'],
		'input'		=> '',

		'response_verbose' 	=> 1,  # Must be set to get test back with response
		'verbose'			=> $self->verbose,
		'do_verbose'		=> $self->do_verbose,
	})) unless defined( $self->default_request );

	$self->control_options->{'local_address'} = '127.0.0.1'
		unless defined($self->control_options->{'local_address'});

	# Load up control now, before requests come in, since we must be local
	# if loading packages.
	# Get a Control for the test-master user loaded into peers.
	$self->GetControl(	$self->peers->[0]->id, $self->peers->[0] );

	# Get the packages and control going but come back for the requests.
	$poe_kernel->run_one_timeslice;
}

=item build_test

This object method is used to build the test, as a Agent::TCLI::Request, and put it
on the queue. It is called by the Testee. Some of this functionality may be
pushed to the Testee soon, so expect this API to change.

=cut

sub build_test {
	my ($self, $testee, $test, $input, $exp1, $exp2, $name) = @_;
	$self->Verbose($self->alias.":build_test: testee(".$testee->addressee.
		")\n\t test($test) input($input)\n\t exp($exp1)",1);
	my ($request, $id);

	if ( ( defined($input) && $input ne '') )
	{
		# check if input is a request object.
		if ( ref($input) =~ /Request/ )
		{
			# verify sender/postback
			if ( ( $request->postback->[0] eq 'PostRseponse' &&
				   $testee->addressee ne 'self' ) ||
				 ( defined($request->postback->[1] ) &&
				   $request->postback->[1] ne $testee->addressee )
			)
			{
				croak("Testee $testee->addressee does not match request" );
			}
			$request = $input;
			$id = $request->id;
		}
		else # put into default request if not
		{
			# clone the default_request
			$request = $self->default_request->clone(1);
			$request->input($input);

			# Insert the proper testee
			if ($testee->addressee ne 'self')
			{
				$request->sender([
					$testee->transport,
					$testee->protocol,
					]);
				$request->postback([
					'PostRequest',
					$testee->addressee,
				])
			}

			# using make_id to faciltate changing ID style in olny one place later
			$request_count[$$self]++;
			$id = $self->make_id( $request_count[$$self]);
			$request->id( $id );

			# Put request onto stack.
			$self->push_requests($request);

			$last_testee[$$self] = $testee->addressee;

		}
	}
	else
	{
		croak("Input required. Nothing in queue") unless defined($request_count[$$self]);
		# Get last request id if none provided
		$id = $self->make_id( $request_count[$$self] );
	}

	unless ( defined $name )
	{
		$name = ( $test =~ qr(not|error) )
			? 'failed '.$input
			: $input;
	}

	$test_count[$$self]++;

	# add test, values, name and number to request_tests.
	# Not doing any checking, so allowing stupidity like repeating tests
	# or putting in conflicting tests....
	push( @{$self->request_tests->{ $id } },
		[ $test, $exp1, $exp2, $name, $test_count[$$self] ] );

	$self->dispatch;

	# return request for future reference.
	return($request);
}

=item dispatch

This internal object method is used to dispatch requests and run POE timeslices
during the test script. An understanding of POE may be necessary to grok
the need for this function.

=cut

sub dispatch {
	my ($self, $style) = @_;

	# Clean out anything in kernel queue
	$poe_kernel->run_one_timeslice;

	my $post_it = $self->post_it($style);

	if ( ( $post_it == 1 ) && ( my $next_request = $self->shift_requests ) )
	{
		$self->Verbose($self->alias.":dispatch: sending request id(".$next_request->id.") " );
		$poe_kernel->post($self->alias, 'SendRequest', $next_request );

		# There are problems with OIO Lvalues on some windows systems....
		$requests_sent[$$self]++;

		# Go ahead and send that out
		$poe_kernel->run_one_timeslice;

		# But wait, are there more?
		$self->dispatch if ( $self->depth_requests );
	}

	# returning $post_it so that it can be checked to see if it is safe to proceed.
	# This could be used by done() to loop until timed out.
	$self->Verbose($self->alias.":dispatch: post_it($post_it)",2);

	return($post_it);
}

=item do_test

This is an internal method to process responses.
B<do_test> actually executes the test and send the output to the TAP processor.
It takes an ARRAYREF for the test and the Agent::TCLI::Response to be checked as
parameters.

=cut

sub do_test {
	my ($self, $t, $response) = @_;

	# Split out test name and test class.
	my ($test, $class) = split('-',$t->[0]);

	my $value;
	my $another = 0;
	my $again = 0;
	# Test classes currently, body, code, time

	if ($class eq 'time')
	{
		# Should time be checked on the first test or on the last?
		# Time will get checked wherever it is placed in the queue
		# before a body/code and is tested agaisnt that response time.
		$value = int( time() ) - $response->get_time();
		# time does not use up a response.
		$another = 1;
	}
	elsif ($class eq 'fail')
	{
		# Got nothing, test nothing.
		$value = '';
	}
	else
	{
		$value = $response->$class();
	}
	# $t is [ test-class , expected, expected2, name ]

    # special case for code 100 / class code
    # Preserves and skips all tests if a 100 is received and not looking
    # for it.
    if ( $class eq 'code' && $value == 100 && $t->[1] != 100 )
    {
    	# skip the test unless testing for 100
		$self->Verbose($self->alias.":do_test: $class value($value) != $t->[1] skipping ");
		# Preserve this test
		$again = 1;
		# skip the rest of the tests for this response too.
    	return ($another, $again);
    }

	my $res;
	# Let's do it.
	$self->Verbose($self->alias.
		":do_test: $test $class value($value) expected(".$t->[1].") ");

	if ($test =~ qr(eq|num|like) )
	{
		$res = $self->builder->$test( $value, $t->[1], $t->[3] );
		$self->builder->diag($response->body) if (!$res && $class eq 'code');
	}
	elsif ($test =~ qr(error) )
	{
		$res = $self->builder->ok( ( $value >= 400 && $value <= 499 ) , $t->[3] );
		$self->builder->diag($response->body) if (!$res);
	}
	elsif ($test =~ qr(success) )
	{
		$res = $self->builder->ok( ( $value >= 200 && $value <= 299 ) , $t->[3] );
		$self->builder->diag($response->body) if (!$res);
	}
	elsif ($test =~ qr(trying) )
	{
		$res = $self->builder->ok( ( $value >= 100 && $value <= 199 ) , $t->[3] );
		$self->builder->diag($response->body) if (!$res);
	}

	if ($test =~ qr(^are) )
	{
		# set again not to use up this test on this resonse
		$again = 1;
	}

	$self->Verbose($self->alias.
		":do_test: $test res($res) another($another) again($again)");

	return ($another, $again);
}

=item get_param ( <param>, [ <id>, <timeout> ] )

B<get_param> is an internal method that supports the Testee get_param command.
It requires a param argument that is the parameter to try and obtain a value
for. It takes an optional request id from a prior request. If not
supplied, it will use the last request made. It also takes an optional
timeout value, which will be passed to B<done_id>
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

	# valid formats to receive the parameter are:
	# param=something
	# param something
	# param="a quoted string with something"
	# param "a quoted string with something"
	# param: a string yaml-ish style, no comments, to the end of the line
	# param: "a quoted string, just what's in quotes"

	my $value;

	# validate id
	unless ( defined($id) && $id )
	{
		# Use last id if not supplied
		$id = $self->make_id( $request_count[$$self]);
	}

	$self->Verbose("get_param: param($param) id($id) timeout($timeout)  ",1);

	$self->done_id( $id, $timeout) if ( defined($timeout) );

	return(undef) unless (exists($self->responses->{$id}));

	$self->Verbose("get_param: id($id) timeout($timeout) count(".
		@{ $self->responses->{$id} }.") ",2);

	# loop through responses, last first
	RESPONSE: foreach my $response ( reverse @{$self->responses->{$id}} )
	{
		$self->Verbose('get_param: body('.$response->body.') ',3);

		# any valid format in double quotes
		if (  $response->body =~ qr($param(?:=|\s|:\s)"(.*?)") )
		{
			$value = $1;
			last RESPONSE
		}
		# = or space followed by a word
		elsif ( $response->body =~ qr($param(?:=|\s)(\S*))  )
		{
			$value = $1;
			last RESPONSE
		}
		# yaml to the end of the line
		elsif ( $response->body =~ qr($param(?::\s)(.*?)\s*$)m )
		{
			$value = $1;
			last RESPONSE
		}

	}
	$self->Verbose("get_param: returning $value");
	return ($value);
}

=item get_responses ( [ <id>, <timeout> ] )

B<get_responses> is an internal method that supports the Testee get_responses
command. It takes an optional request id from a prior request. If not
supplied, it will use the last request made. It also takes an optional
timeout value, which will be passed to B<done> to wait for all responses
to come in.
It returns the text from all available responses, separated by a pair
of newlines.

=cut


sub get_responses {
	my ($self, $id, $timeout) = @_;

	my $value;

	# validate id
	unless ( defined($id) && $id )
	{
		# Use last id if not supplied
		$id = $self->make_id( $request_count[$$self] );
	}
	$self->Verbose("get_responses: id($id)",3);

	$self->done_id( $id, $timeout) if ( defined($timeout) );

	return(undef) unless (exists( $self->responses->{$id} ) );

	$self->Verbose("get_responses: id($id) count(".@{ $self->responses->{$id} }.") ",1);
	# loop through responses
	RESPONSE: foreach my $response ( reverse @{ $self->responses->{$id} } )
	{
		$value .= $response->body."\n\n";
	}
	$self->Verbose("get_responses: returning $value");
	return ($value);
}

=item make_id

B<make_id> is used to create a request ID for new requests. It is a separate
method to ease mainenance in case it needs to change in the future. It
takes an optional integer as a parameter, or will default to the current
request_count.

=cut

sub make_id {
	my ($self, $num) = @_;

	my $id = defined ($num) ? $num : $self->request_count;

	# Maybe put in hostname and PID or some other unique ID prefix someday?
	# or maybe not

	$self->Verbose($self->alias.":make_id: num($num) id($id)",2);
	return ( $id );
}

=item post_it

This internal method controls whether to dispatch the next test. It supports
different styles of running tests, though currently the style is not
user configurable and manipulation of the style is not tested.

For future reference and to encourage assistance in creating a user interface to style, they are:

B<default> or B<syncsend> - This allows a test to be dispacthed when the
acknoledgement is received that the previous test has been received OK. This
does not wait for the previous test to complete.

B<syncresp> or B<done> - This will not dispatch any test until the previous test
has completed. There are many testing scenarios where this makes no sense.
There may be scenarios where it does make sense, and htat is why it is here.
A similar effect can be had with the B<done> test.

B<asynch> - This dispatches a test as soon as it is ready to go. Sometimes
this may allow a local test to complete before a prior remote test has
been acknowledged, so it is not the default.

=cut

sub post_it{
	my ($self, $style) = @_;
	my $post_it = 0;

	# Currently running partially synchronous by default.
	$style = 'default' unless defined( $style );

	# TODO Option to set default for all runs.
	if ( $dispatch_counter[$$self] == $dispatch_retries[$$self] )
	{
		# if we stalled on something, then skip it
		$post_it = 1;
	}
	elsif ( !defined($style) || $style =~ /default|syncsend/ )  # partially synchronous / ordered
		# make sure we got some response to the previously sent request before sending
	{
		# Have we seen a response yet for the last request?
		$self->Verbose($self->alias.":post_it:$style: sent(".$requests_sent[$$self].") ",1);
		if ( $requests_sent[$$self] == 0 ||
			exists( $responses[$$self]{ $self->make_id($requests_sent[$$self]) } )
		)
		{
			$post_it = 1;
		}
	}
	elsif ( $style =~ /syncresp|done|ordered/ )  # completely synchronous / ordered
		#make sure all created requests have responses before sending another
	{
		my $rmc = $self->responses_contiguous;
		if ( $request_count[$$self] == $rmc )
		{
			$post_it = 1;
		}
		$self->Verbose($self->alias.":post_it:$style: count(".
			$request_count[$$self].") contiguous(".$rmc.")",);
	}
	elsif ( $style =~ /async/  )  # asynchrounous, no other checks necessary
		# who cares, send it now.
	{
			$post_it = 1;
	}
	$self->Verbose($self->alias.":post_it: ($post_it)");
	return($post_it);
}

=item responses_contiguous (   )

Sets responses_max_contiguous correctly by starting at the last value and
incrementing until a response has not been recived. Return
responses_max_contiguous.

=cut

sub responses_contiguous {
	my ($self, $id) = @_;

	while  ( defined($self->responses->{
		$self->make_id( $self->responses_max_contiguous + 1) } ) )
	{
		$responses_max_contiguous[$$self]++;
	}
	return ( $self->responses_max_contiguous );
} # End responses_contiguous

=item Dispatch

This POE event handler takes care of dispatching once POE is running fully.
It maintains a counter to ensure that the test queue does not become stuck.
If the counter is exceeded (the queue is stuck), it will send a test without
regard to the response from B<post_it>.

=cut

sub Dispatch {
	my ($kernel,  $self, $session, $delay) =
  	  @_[KERNEL, OBJECT,  SESSION, 	   ARG0];
	$self->Verbose($self->alias.":Dispatch: {".$delay.
		"} dc(".$dispatch_counter[$$self].") requests(".$self->depth_requests.") ");

	my $next_request;

	if ( ! $self->depth_requests )
	{
		# Whohoo. we're done, let timeout know bu setting counter.
		$dispatch_counter[$$self] = $dispatch_retries[$$self];
	}
	elsif ( ( $self->post_it ) && ( $next_request = $self->shift_requests ) )
	{
		$self->Verbose($self->alias.":Dispatch: sending request id(".$next_request->id.") " ,1,);
		$kernel->yield( 'SendRequest', $next_request );

		# There are problems with OIO Lvalues on some windows systems....
		$requests_sent[$$self]++;

		# But wait, are there more?
		$kernel->delay('Dispatch', $delay, $delay);

		# We did something, clear out counter.
		$dispatch_counter[$$self] = 0;
	}
	elsif ( $dispatch_counter[$$self] >= $dispatch_retries[$$self] &&
		( $next_request = $self->shift_requests ) )
	{
		$self->Verbose($self->alias.":Dispatch: STALLED sending request id(".
			$next_request->id.") overriding post_it" ,1,);
		$kernel->yield( 'SendRequest', $next_request );

		$requests_sent[$$self]++;

		# But wait, are there more?
		$kernel->delay('Dispatch', $delay, $delay);

		# We did something, clear out counter.
		$dispatch_counter[$$self] = 0;
	}
#	elsif ( $dispatch_counter[$$self] == $dispatch_retries[$$self] )
#	{
#		$self->Verbose($self->alias.":Dispatch: STALLED requests(".$self->depth_requests.") ",0 );
#		# Stalled out
#		foreach my $test ( @{$self->requests} )
#		{
#			$self->Verbose($self->alias.":Dispatch: test dump(".$test->dump(1).") ");
#		}
#		return;
#	}
	else
	{
		#start counting to doom...
		$dispatch_counter[$$self]++;
		$kernel->delay('Dispatch', $delay, $delay );
	}

	return('Dispatch_'.$self->alias);
}

=item PostRequest

B<PostReuqest> is a required POE event handler for all Transports. Well, all
transports except this one. It currently does nothing.

=cut

sub PostRequest {

	# assign request ID, if input is blank, then use last request ID.

	# Post request will look a lot like build test?

	# if input is blank, the send to PostResponse otherwise send to
	# whomever is doing the request. Does it matter what order the requests
	# are checked in PostResponse? It shouldn't, I think.
}

=item PostResponse

B<PostResponse> is a required POE event handler for all Transports.
It takes a TCLI Response as an argument. Typically
it is called by another Transport to deliver the Response.

It will queue the Reponses in an array in the
responses hash keyed by response->id. It will call B<do_test> to complete
the tests as appropriate.

=cut

sub PostResponse {
	my ($kernel,  $self, $sender, $response) =
  	  @_[KERNEL, OBJECT,  SENDER,      ARG0];
	$self->Verbose($self->alias.":PostResponse: sender(".$sender->ID.") Code(".$response->code.") \n");

	# Test always terminates a response transmission. The buck stops here,
	# unlike other transports

	# TODO Need to figure out how to decide it is time to start checking the tests!

	# Hmm. I donn't want to optimize this better with another object right now.
	# Push response into a responses array in a hash keyed on id.
	push( @{ $responses[$$self]->{$response->id} }, $response  );

	$self->Verbose($self->alias.":PostResponse: responses(".@{ $responses[$$self]->{$response->id} }.
		") ",3,$responses[$$self]->{$response->id} );

	# Work off of the first response for tracking.

#	my $response_prime = $responses[$$self]->{$response->id}[0];

	# we chould only check one body/code test per response? Or one of each type.
	# Hmmm. Not very intuitive either way.
	# Gotta be that body/code always use up a response,  or vice/versa....
	# but have to deal with 100s

	my $test;
	my $again = 0;
	my $index = 0;
	my $another = 1;
	# some tests are greedy and use up the response, others are not
	# $another is used to track that.
	# some tests get used up with a response (is) some don't (are)
	# $again is used for that
	while ( $another )
	{

		$test = $self->request_tests->{ $response->id }->[$index];
#		$test = $response_prime->shift_test_array;

		$self->Verbose($self->alias.":PostResponse: test dump ",3,$test);
		if (defined ($test))
		{
			($another, $again) = $self->do_test($test, $response);

			# allow tests to apply to more than one response by setting again
			unless ( $again )
			{
				shift(@{$self->request_tests->{ $response->id } });
			}

			# adjust index only if again, otherwise we just shifted the array
			$index += $again;
		}
		else
		{
			# There are not any more to do. :)
			$another = 0;
			$self->Verbose("PostResponse: response ".$response->id." received but no more tests");
		}
		next;
	}

	$self->responses_contiguous;

#	if ( $response_prime->depth_test_array == 0 )

	if ( scalar(@{$self->request_tests->{ $response->id } }) == 0 )
	{
		# TODO the way to do this is to have a test type that counts

#		if ( defined( $response->get_responses_wanted) &&
#			$response->get_responses_wanted == $response->response_count )
#		{
#			$self->builder->ok( 1, " Request ".$response->id." got wanted responses " );
#		}

		$requests_complete[$$self]++;
	}
	elsif ( scalar(@{$self->request_tests->{ $response->id } }) >= 0 )
	{
		my $complete = 1;
		# if all we have left is are tests, then we can be complete.
		foreach $test ( @{$self->request_tests->{ $response->id } } )
		{
			$complete = ($complete && $test->[0] =~ /^are/);
		}
		$requests_complete[$$self] += $complete;
	}
}

=item SendChangeContext

B<SendChangeContext> is a POE event handler required for all Transports. Well,
all I<other> Transports, as this one still thinks it is special enough not to
need to do anything here.

=cut

sub SendChangeContext {
	my ($kernel,  $self, $control ) =
	  @_[KERNEL, OBJECT,    ARG0 ];
	# for jabber, we announce context with presence.
	# for a terminal, it might be a prompt...
	$self->Verbose($self->alias.":SendChangeContext: for control".$control->id());

}

=item SendRequest

B<SendRequest> is a POE event handler that is required for all Transports.
It takes a Agent::TCLI::Request as an argument

=cut

sub SendRequest {
	my ($kernel,  $self, $sender, $request) =
  	  @_[KERNEL, OBJECT,  SENDER, 	ARG0  ];
	$self->Verbose($self->alias.":SendRequest: sender(".$sender->ID.") request(".$request->id.") \n");
	$self->Verbose($self->alias.":SendRequest: request dump \n",3,$request);

	# send request
		# Need to think about sender stack...

		# if there is nothing on the stack, it get's populated with
		# test and posted to control.

		# if another transport is on the stack, it puts itself on the bottom?
		# Then sends it to the local transport for handling.

		# The local transport will send it to the remote transport, putting
		# itself (the local) on the stack as well. No, it needs to take off the remote when it sends it there.

		# we're not via headers here. We just need to know where to go
		# Transport should take themselves out and put in where they got the request
		# so it can go back.


	# Put time in request for tracking
	$request->set_time(time());

	if ( $request->sender->[0] eq $self->alias )
	{
		$self->Verbose($self->alias.":SendRequest: local request \n");
		$self->Verbose($self->alias.":SendRequest: request dump ".$request->dump(1),3 );
		# Get a Control for the test-master user loaded into peers.
		my $control = $self->GetControl(	$self->peers->[0]->id, $self->peers->[0] );
		# Post to our Control
		# Sometimes, control has not started, so we wiat if we have to.
		if ( defined($control->start_time) )
		{
			$kernel->post( $control->id => 'Execute' => $request );
		}
		else
		{
			$kernel->delay('ControlExecute' => 1 => $control, $request );
		}
	}
	else
	{
		$self->Verbose($self->alias.":SendRequest: punting the request \n");
		# Take off Sender and postback and put us at the end.
		# assuming here that wherever this is going, we don't have to
		# worry about setting up the Control....
		my $sender = $request->shift_sender;
		my $postback = $request->shift_postback;
		$request->push_sender($self->alias);
		$request->push_postback('PostResponse');

		$kernel->call( $sender => $postback => $request );
	}

	return(  );
}

=item Timeout

B<Timeout> is a POE event handler that makes sure that a test script completes
and no requests leave the system waiting too long for a response. It takes
an argument of the delay, in seconds, that it will wait until checking again.

=cut

sub Timeout {
	my ($kernel,  $self, $session, $delay, ) =
	  @_[KERNEL, OBJECT,  SESSION,     ARG0,  ];
	$self->Verbose($self->alias.":Timeout: {".$delay.
		"} run(".$self->running.")  dc(".$dispatch_counter[$$self].") dr(".
		$dispatch_retries[$$self].") tc(".$timeout_counter[$$self].") tr".
		$timeout_retries[$$self].") requests(".$self->depth_requests.") ");

	# Is Dispatch done with the queue?
	# We wait until running before using an empty queue as goood enough.
	if ( ( $self->running && $self->depth_requests == 0 ) ||
		$dispatch_counter[$$self] == $dispatch_retries[$$self] )
	{
		if ( $request_count[$$self] == $requests_complete[$$self] ||
			 $timeout_counter[$$self] == $timeout_retries[$$self] )
		{
			$kernel->yield('_shutdown');
			return;
		}
		else
		{
			$kernel->delay( 'Timeout', $delay, $delay, );
			$timeout_counter[$$self]++;
		}
	}
	# Dispatch now taking care of requests still in queue and we'll just wait until
	# it is done.
	else
	{
		$kernel->delay( 'Timeout', $delay, $delay, );
	}
}

=item GetControl ( id )

Inherited from Agent::TCLI::Trasnport::Base

=cut

=item _shutdown

Shutdown begins the shutdown of all child processes.

=cut

sub _shutdown :Cumulative {
    my ($kernel,  $self, $session) =
    @_[KERNEL, OBJECT,  SESSION];
	$self->Verbose($self->alias.':_shutdown:');

	foreach my $package ( @{$self->control_options->{'packages'} })
	{
		$kernel->post( $package->name => '_shutdown'  );
	}

#    $kernel->alias_remove( $self->alias );
	return ('_shutdown '.$self->alias )
}

sub _start {
	my ($kernel, $session, $self) = @_[KERNEL, SESSION, OBJECT];

	# Trying to run this as cumulative is not working. Not sure why.
	# Just being inefficient instead of debugging.

	# are we up before OIO has finished initializing object?
	if (!defined( $self->alias ))
	{
    $self->Verbose($session->ID.":_start: OIO not started delaying ");
		$kernel->yield('_start');
		return;
	}

    $kernel->alias_set($self->alias);

    $self->Verbose($self->alias.":_start: Starting alias(".$self->alias.")");

	# Set up recording.
	$self->requests_sent(0) ;
	$self->requests_complete(0);

	# initialize counters
	$self->dispatch_counter(0);
	$self->timeout_counter(0);

	# This will call timeout in 5 seconds
	# So there is a 30 seconds delay from the sending of the last test
	# before we stop by default.
	$timeout_id[$$self] = $kernel->delay_set( 'Timeout', 5, 5 );

	# well, tha above would be true if the kernel was running gung ho. But we're
	# calling timeslices willy nilly until all requests are queued, so it turns out
	# that Timeout gets called in every timeslice regardless of delay, but
	# this is good because it is the one queud event that keeps everything
	# from stopping.

	# When debugging POE Event streams, this might help.
	return('_start'.$self->alias);
}

=item _stop

This POE event handler is called when POE stops a Transport.

=cut

sub _stop {
	my ($kernel, $session, $self) = @_[KERNEL, SESSION, OBJECT];
	$self->Verbose($self->alias.":".":stop session stopped...\n" );

	# did we send all requests?
	$self->builder->is_num( $self->depth_requests, 0,
		$self->alias." test queue empty" );


	$self->done(0,"Run finished, all tests completed");

	# Sometime timeout is sneaking itself back onto stack during shutdown.
	$self->Verbose($self->alias.":_stop: removing alarms",1,$kernel->alarm_remove_all() );

	# TODO maybe hold on on all response count tests until done for overages?

	# When debugging POE Event streams, this might help.
	return('_stop '.$self->alias);
}

1;

#__END__

=back

=head1 AUTHOR

Eric Hacker	 hacker can be emailed at cpan.org

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
