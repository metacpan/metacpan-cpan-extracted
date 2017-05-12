package Agent::TCLI::Package::Tail;
#
# $Id: Tail.pm 59 2007-04-30 11:24:24Z hacker $
#
=pod

=head1 NAME

Agent::TCLI::Package::Tail - A Tail command

=head1 SYNOPSIS

	# Within a test script

	use Agent::TCLI::Package::Tail;

	# set the list of packages
	my @packages = (
		Agent::TCLI::Package::Tail->new({
			'verbose'		=> \$verbose,
			'do_verbose'	=> sub { diag( @_ ) },
		}),
	);

=head1 DESCRIPTION

This module provides a package of commands for the TCLI environment. Currently
one must use the TCLI environment (or browse the source) to see documentation
for the commands it supports within the TCLI Agent.

B<Agent::TCLI::Package::Tail> provides commands to set up filtered tails of files.
Tails can be established as a I<watch> which will report on every match, or as
a I<test> which supports use in a functional testing activity with discrete
matching and reporting characteristics. It supports regex matching of the lines.

It should support more complex testing where POE Filters deliver objects
that can be queryied in an OK test, but that has not been tested and is likely
buggy. An example of this use would be to have a POE Filter deliver Snort Alert
objects which could then be queried if their source addresess was in a range.

=head1 INTERFACE

This module must be loaded into a Agent::TCLI::Control by an
Agent::TCLI::Transport in order for a user to interface with it.

=cut

use warnings;
use strict;

use Object::InsideOut qw( Agent::TCLI::Package::Base );

use POE qw(Wheel::FollowTail);

use Agent::TCLI::Command;
use Agent::TCLI::Parameter;
use Agent::TCLI::Package::Tail::Line;
use Agent::TCLI::Package::Tail::Test;

use Getopt::Lucid qw(:all);

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: Tail.pm 59 2007-04-30 11:24:24Z hacker $))[2];

=head2 ATTRIBUTES

These attrbiutes are generally internal and are probably only useful to
someone trying to enhance the functionality of this Package module.
It would be unusual to set any of these attributes on creation of the
package for an Agent. That doesn't mean you can't.

=over

=item files

A hash of the 'files' being tailed.
B<files> will only contain hash values.

=cut
my @files			:Field
					:Type('hash')
					:All('files');

=item line_cache

An array for holding the last few lines to enable lookbacks
B<line_cache> will only contain Array values.

=cut
my @line_cache		:Field
					:Type('Array')
					:Arg('name'=>'line_cache', 'default' => [ ] )
					:Acc('line_cache');

=item test_queue

A queue of all the tests waiting to be activated by triggers
B<test_queue> will only contain Array values.

=cut
my @test_queue		:Field
					:Type('Array')
					:All('test_queue');

=item active

A hash keyed on num of all the tests currently active.
B<active> will only contain hash values.

=cut
my @active			:Field
					:Type('hash')
					:Arg('name'=>'active', 'default'=> { '0' => 1 } )
					:Acc('active');

=item ordered

The default setting for ordered test processing.
B<ordered> should only contain boolean values.

=cut
my @ordered			:Field
#					:Type('boolean')
					:Arg('name'=>'ordered','default'=>0)
					:Acc('ordered');

=item interval

The default interval setting
B<interval> should only contain integer values.

=cut
my @interval		:Field
					:Type('numeric')
					:Arg('name'=>'interval', 'default'=> 0.05 )
					:Acc('interval');

=item line_max_cache

Maximum size of the line cache, in lines.
B<line_max_cache> will only contain numeric values.

=cut
my @line_max_cache	:Field
					:Type('numeric')
					:Arg('name'=>'line_max_cache','default'=>10)
					:Acc('line_max_cache');

=item line_hold_time

Time to hold lines in the cache, in seconds.
B<line_hold_time> will only contain numeric values.

=cut
my @line_hold_time	:Field
					:Type('numeric')
					:Arg('name'=>'line_hold_time','default'=>30)
					:Acc('line_hold_time');

=item test_max_lines

Default setting for how many lines a test will observe before failing. Defaults to zero (unlimited).
B<test_max_lines> will only contain numeric values.

=cut
my @test_max_lines	:Field
					:Type('numeric')
					:Arg('name'=>'test_max_lines','default'=>10)
					:Acc('test_max_lines');

=item test_match_times

Default setting for how many times a test should match. Default is 1.
B<test_match_times> will only contain numeric values.

=cut
my @test_match_times :Field
					:Type('numeric')
					:Arg('name'=>'test_match_times','default'=>1)
					:Acc('test_match_times');

=item test_ttl

The default time to live for a test before failing. The default is 0, no expiration.
B<test_ttl> will only contain numeric values.

=cut
my @test_ttl		:Field
					:Type('numeric')
					:Arg('name'=>'test_ttl','default'=>30)
					:Acc('test_ttl');

=item test_verbose

The default test verbose setting.
B<test_verbose> will only contain numeric values.

=cut
my @test_verbose	:Field
					:Type('numeric')
					:Arg('name'=>'test_verbose','default'=>0)
					:Acc('test_verbose');

=item test_feedback

The default feedback setting for new tests.
B<test_feedback> will only contain Numeric values.

=cut
my @test_feedback	:Field
					:Type('Numeric')
					:Arg('name'=>'test_feedback','default'=>0)
					:Acc('test_feedback');

=item line_count

A running count of all the lines seen.
B<line_count> will only contain numeric values.

=cut
my @line_count		:Field
					:Type('numeric')
					:Arg('name'=>'line_count','default'=>0)
					:Acc('line_count');

=item test_count

A running count of the tests that have arrived in the queue.
B<test_count> will only contain numeric values.

=cut
my @test_count		:Field
					:Type('numeric')
					:Arg('name'=>'test_count','default'=>0)
					:Acc('test_count');

=item activated_count

A running count of the tests that have been activated.
B<test_count> will only contain numeric values.

=cut
my @activated_count	:Field
					:Type('numeric')
					:Arg('name'=>'activated_count','default'=>0)
					:Acc('activated_count');


=item tests_complete

A running count of the number of tests that have completed.
B<tests_complete> will only contain numeric values.

=cut
my @tests_complete	:Field
					:Type('numeric')
					:Arg('name'=>'tests_complete','default'=>0)
					:Acc('tests_complete');

=back

=head2 METHODS

Most of these methods are for internal use within the TCLI system and may
be of interest only to developers trying to enhance this module.

=over

=item Append <input>, <wheel_id>

This POE Event handler receives the tail events and creates the
line objects to insert into the line_cache.  It typically
accepts events from POE::Wheel::FollowTail. It may also be
called directly from another POE Session, in which case only
the input to be logged should be provided. It will insert the
sending POE Session as the line->source if no wheel_id is provided.

=cut

sub Append {
    my ($kernel,   $self, $sender, $input, $wheel_id) =
      @_[KERNEL,  OBJECT,  SENDER,  ARG0,      ARG1];

	# This and Log are virtually identical. Maybe merge someday?

	return unless defined $input;

	# assign source to either a wheel or another POE session
	my $source = defined($wheel_id)
		? $self->GetWheelKey($wheel_id, 'source')
		: $sender ;

	$self->Verbose("append: input(".$input.") from ".$source, 2 );

	$line_count[$$self]++;

	my $type = ref($input);
	$type = "line" if ($type  eq '');

	# push line onto cache
	$self->push_line_cache( Agent::TCLI::Package::Tail::Line->new(
		'input'			=>	$input,
		'count'			=>  $line_count[$$self],
		'birth_time'	=>  time(),
		'ttl'			=>  time()+ $self->line_hold_time,
		'source'		=>	$source,
		'type'			=>	$type,
	 ));

	# remove first-in line if total line count exceeded.
	if ( $self->depth_line_cache > $self->line_max_cache )
	{
		$self->Verbose('Too many lines, removing...');
		shift ( @{$self->line_cache} );
	}

	# post new event to active states
	foreach my $state ( sort keys %{$self->active} )
	{
		$kernel->yield( $state => 'Append', $self->line_count );
	}
}

=item Activate

This POE event handler activates tests in the queue by registering an
event with SimpleLog and creating an event handler.
This whole process is currently ineffecient and will hopefully get
redone sometime.

=cut

sub Activate {
   my ($kernel,   $self,  ) =
      @_[KERNEL,  OBJECT,  ];

	my $counter = $self->activated_count;

	$self->Verbose('Activate: counter('.$counter.')  ',2);

	# remember that counter is an array index and is one less than the size...
	if ($self->depth_test_queue == 0 || $counter >= $self->depth_test_queue )
	{
		$kernel->delay('Activate',$self->interval );
		return('nothing activated');
	}

	my $test = $self->test_queue->[$counter];
	$self->Verbose('Activate: counter('.$counter.')  dump ',4,$self->test_queue);
	$self->Verbose('Activate: test_num('.$test->num.')  dump '.$test->dump(1),4);

	$self->increment_activated_count;

	$kernel->delay('Activate',$self->interval );

	my $num = $test->num;

	#put into active list
	$self->active->{$num} = $test;

	# set up test TTL. We add the time so that we now know the exact
	# expiration of this event.
	# Note that a sufficiently large number for TTL could get a test to last
	# for years...
	$test->increment_ttl( time() ) if ( $test->ttl != 0 );

	$self->Verbose('Activate: counter('.$counter.') time('.time().') test dump ',3,$test );

	# Set up state to receive an event for this test
	$kernel->state( $num => $self => $test->handler );
	$self->Verbose('Activate: state('.$num.') handler('.$test->handler.')',1);

	# kick off state to process cache
	$kernel->yield( $num );

	return('activated '.$num );
}

=item Check

The POE event handler is what does the actual test/watch on the line
objects.

=cut

sub Check {
    my ($kernel,   $self, $sender, $session, $state ) =
      @_[KERNEL,  OBJECT,  SENDER,  SESSION,  STATE ];

    # Note the right now we're ignoring the ARGS which has the
    # Line number, since we keep track of that in each test.
    # The line number is not supplied if we're processing the cache
    # This might be used for optimization in the future

	$self->Verbose('Check: state('.$state.') lines('.$self->depth_line_cache.
		') completed('.$self->tests_complete.') ',1);
	$self->Verbose('Check: state('.$state.') test queue dump ',5,$self->test_queue );

	# OK, so I actually had a bug where I created a Check event with no event name.
	return unless defined ($state);

	my $test = $self->test_queue->[$state -1];
	$self->Verbose('Check: state('.$state.') test dump ',4,$test );

	# Catch any events posted after this test completed
	return if ( $test->complete );

	# if ordered, make sure previous test has completed
	# BUG This only works if all previous tests are ordered.
	# Though it mostly does it right.
	$self->Verbose('Check: ordered('.$test->ordered.') state('.$state.
		') previous complete('.$self->test_queue->[$state - 2]->complete.
		') complete('.$self->tests_complete.')',1);

	if ( $test->ordered && ( $state > 1 ) &&
		 !$self->test_queue->[$state - 2]->complete
	)
	{
		$self->Verbose('Check: state('.$state.') ordered is on, previous not complete.');
		return;
	}

	# Get time here so that all checking uses same time
	my $time = time();

	my ($because, $comment, $code, $input, $matchline);
	my $ok;

	#loop over line of input (in order)
	my $line_index = 0;
	LINE: while ( $line_index < @{$line_cache[$$self]} )
	{
		my $line = $self->line_cache->[$line_index];
		$ok = 0;
		$self->Verbose('Check: state('.$state.') LINE dump  ',4,$line );
		# if line.index_counter > test.index_counter
		# this is a line we haven't checked out
		$self->Verbose('Check: num('.$test->num.') $line->count('.$line->count.
			') $test->last_line('.$test->last_line.')', 1 - $test->verbose );
		if ($line->count > $test->last_line )
		{
			$input = $line->input;
	    	# get test
			$code = $test->code;

			$self->Verbose('Check: state('.$state.') input('.$input.
				') $code->($input) = ('.$code->( $input ).')',2);
			$self->Verbose('Check: num('.$test->num.') input('.$input.
 				   ') $code->($input) = ('.$code->( $input ).')',0)
 				   if ($test->verbose);

			# remove line if match, increment count
			if ( $code->( $input ) )
			{
				$ok = 1;
				$test->increment_match_count;
				# TODO insert optional line pruning...
				$matchline = splice( @{$self->line_cache}, $line_index, 1 );
				$self->Verbose("Check: lc(".$line->count.") ok($ok".
					") li($line_index) matchline ".$matchline->dump(1),2 )
 				   if ($test->verbose);
			}
#			$self->Verbose('Check: in loop('.$line->count.') ( test dump ',2,$test );

    		# set test.index_counter to line's
    		$test->last_line ($line->count);

			$test->increment_line_count;

			# report line if feedback and match or verbose
			if ($test->feedback && ( $ok || $test->verbose) )
			{
				$test->request->Respond( $kernel, $input, 200);
			}

			$self->Verbose('Check: num('.$test->num.') line_count('.
				$test->line_count.') max_lines('.$test->max_lines.
				") passed(".$test->match_count.") last_line{".
				$test->last_line.')',0 )
 				if ($test->verbose);

			# check if we passed enough times
			if ( $ok && $test->match_count == $test->match_times )
			{
				$self->Verbose('Check: passed, skipping rest of lines',2);
				$test->success(1);
				last LINE;
			}

			#check lines_seen and indicate failed test if necessary
			if ( ( $test->max_lines != 0 &&
				$test->line_count >= $test->max_lines) )
			{
				$self->Verbose('Check: fail state('.$state.') TEST dump ',2,$test );
				$because .= "Seen too many lines. Saw (".$test->line_count.") max(".
					$test->max_lines.") passed(".$test->match_count.") \n".
					"Last line: ".$input;
				last LINE;
			}
		}
		# if it passed, we took out the line, so don't increment.
		$line_index++ unless($ok);
	}

#	$self->Verbose('Check: post loop state('.$state.') test dump ',2,$test );
#	$self->Verbose('Check: post loop $ok('.$ok.') matchline',2,$matchline);

	if ( ($test->match_times != 0) && ($test->match_count == $test->match_times) )
	{
		$kernel->call($self->name => 'Complete' => $state => 'ok' );
		$test->complete(1);
	}
	# check clock and fail test if necessary
	elsif ( ( $test->ttl != 0 ) && ( $time > $test->ttl ) )
	{
		$because .= "Timer expired. Time(".$time.")  TTL(".$test->ttl.
			") Diff(".($test->ttl - $time).")";
	}

	if ( ($test->match_times != 0) && $because && not $test->success )
	{
		$self->Verbose("Check: failing ok($ok) because'$because'");

		$kernel->call($self->name => 'Complete' =>  $state => 'not ok' => $because );
		$test->complete(1);
	}

	# if we're done, clean up
	if ( $test->complete )
	{
		# remove the test from active list
		delete($self->active->{$test->num});

		# remove the session state
		$self->Verbose('Complete: removing: state('.$test->num.')',1);
		$kernel->state( $state );
	}
}

=item Complete

This POE event handler handles the response when a test/watch
is complete.

=cut

sub Complete {
    my ($kernel,   $self, $session, $state, $result, $because ) =
      @_[KERNEL,  OBJECT,  SESSION,   ARG0,	   ARG1,     ARG2 ];
	$self->Verbose("Complete: state(".$state.") result(".$result.
		") ");

	my $test = $self->test_queue->[$state -1];
	$self->Verbose('Check: state('.$state.') test dump ',4,$test );
	my $request = $test->request;

	my ($txt, $code);
	if ( $result eq 'ok' )
	{
		$test->success(1);
		$txt = 'ok  '.$test->name;
		$code = 200;
	}
	elsif ( $result eq 'not ok')
	{
		# TODO. Need a better way of returning the because for diagnostics?
		$test->success(0);
		$txt = 'not ok - '.$test->name." \n $because";
		$code= 417;
	}
	else
	{
		$self->Verbose("/n/nBAD COMPLETE CALL/n/n");
		$self->Verbose("Result ($result) because ($because) test dump",1,$test);
		return(0);
	}

	$test->complete(1);
	$self->increment_tests_complete;

	$request->Respond( $kernel, $txt , $code );

	delete( $self->active->{$test->num} );

	$self->Verbose("Complete test '".$test->name."' (".$test->num.") code($code)",1);
	return(1);
}

=item FileReset

This POE event handler should do something when a tailed file is reset, but
it doesn't. Ideas are welcome.

=cut

sub FileReset {
	#TODO File Reset handler.
}

=item Log

This POE event handler is used to introduce line objects from sources other than
the POE::Wheel::FollowTail.

=cut

sub Log {
    my ($kernel,  $self, $sender, $state, ) =
      @_[KERNEL, OBJECT,  SENDER,  STATE, ];
	$self->Verbose("Log:  state(".$state.")  ");

	# This and Append are similar. Maybe merge parts someday?
	my $test = $self->test_queue->[$state -1];
	$self->Verbose('Log: state('.$state.') test dump ',4,$test );

	my $request = $test->request;

	# deprecate this?
	# set test last_line for Check
	$test->last_line($line_count[$$self]);

	$kernel->call( $self->name, 'Append', $test->request->input );

#	$line_count[$$self]++;
#
#	my $input = $request->input;
#	my $type = ref($input);
#	if ($type  eq '')
#	{
#		# if we're plain text then join args for input because real input has
#		# 'log' at the beginning.
#		$type = "line";
#		$input = join(' ', @{$request->args});
#	}
#
#	# push line onto cache
#	push( @{$line_cache[$$self]}, Agent::TCLI::Package::Tail::Line->new(
#		'input'			=>	$input,
#		'count'			=>  $line_count[$$self],
#		'birth_time'	=>  time(),
#		'ttl'			=>  time() + $self->line_hold_time,
#		'source'		=>	'*log*',
#		'type'			=>	$type,
#	 ));
#
#	# remove first-in line if total line count exceeded.
#	if ( $self->depth_line_cache > $self->line_max_cache )
#	{
#		$self->Verbose('Too many lines, removing...');
#		shift ( @{$self->line_cache} );
#	}
#
#	foreach my $state ( sort keys %{$self->active} )
#	{
#		$kernel->yield( $state => 'Append', $self->line_count );
#	}

	$kernel->yield('Complete' =>  $state => 'ok' );

#	$request->Respond($kernel, 'logged line ('.$self->line_count.") ",200 );

	$self->Verbose('Log: removing: state('.$state.')',1);
	$kernel->state( $state );
}

=item PruneLineCache

This POE event handler periodically runs to check for lines that have been in
the cache too long and removes them.

=cut

sub PruneLineCache {
    my ($kernel,   $self, ) =
      @_[KERNEL,  OBJECT, ];
	my $lines = $self->depth_line_cache;
	$self->Verbose('PruneLineCache: lines('.$lines.') ');

	$self->Verbose('PruneLineCache: cache dump ('.$lines.') ',3,$self->line_cache);

	if ( $self->depth_line_cache > 0 )
	{
		# Set time here so that all pruning uses same time
		my $time = time();

		my $line_index = 0;
		foreach my $line ( @{$self->line_cache} )
		{
			# The line ttl is set at line creation. This allows the ttl
			# to be modified along the way.
			if ( $line->ttl < $time )
			{
				splice( @{$self->line_cache}, $line_index, 1 );
				$self->Verbose('PruneLineCache: removed line('.$line->count.') ',2);
			}
			$line_index++;
		}
	}
	# schedule the next check
	$kernel->delay('PruneLineCache',10)
		unless ( $self->tests_complete >= $self->depth_test_queue );

}

=item SetFollowTailWheel

This POE event handler sets up the POE::Wheel::FollowTail to send
events to our Append handler for each new File. I suppose at some point
I ought to write the corresponding DeleteFollowTailWheel.

=cut

sub SetFollowTailWheel {
    my ($kernel,   $self, $params ) =
      @_[KERNEL,  OBJECT,   ARG0 ];

	my $filter = defined( $params->{'filter'} ) && ( $params->{'filter'} ne '' )
		 ? $params->{'filter'} :  POE::Filter::Line->new();

	my $interval = defined( $params->{'interval'} ) && ( $params->{'interval'} ne '' )
		 ? $params->{'interval'} : 5;

	my %seek;
	if ( defined($params->{'seekback'}) && $params->{'seekback'} ne '' )
	{
		$seek{'SeekBack'} = $params->{'seekback'}
	}
	elsif ( defined($params->{'seek'}) && $params->{'seek'} ne '' )
	{
		$seek{'Seek'} = $params->{'seek'}
	}

	my $wheel = POE::Wheel::FollowTail->new(
    	Filename     => $params->{'file'},               # File to tail
    	Filter       => $filter, 			  		   # How to parse it
    	PollInterval => $interval,           # How often to check it
    	InputEvent   => 'Append',  			# Event to emit upon input
    	ErrorEvent   => 'RunError',  			# Event to emit upon error
    	ResetEvent   => 'FileReset',  			# Event to emit on file reset
		%seek,						# Can't have both seek & seekback
	);

	# TODO error checking

	$self->Verbose('File ('.$params->{'file'}.') being watched by wheel ID('.$wheel->ID.') ' );

	$self->SetWheel($wheel);
	$self->SetWheelKey($wheel, 'source' => $params->{'file'} );
	$files[$$self]{ $params->{'file'} } = { 'wheel' => $wheel->ID };

	return (1);
}

=item Wally

This POE event handler doesn't do anything, because sometimes
we must have a state that doesn't respond to work requests.
For one never knows when we just throw some event out there if someone
else might pick it up by _default and do something with it.
This way we KNOW it won't get done.

=cut

sub Wally {
	return 0;
	# This way we KNOW it won't get done.
}

=item test

This POE event handler executes the test/watch commands. It is called by the
Control and takes a Request as an argument.

=cut

sub test {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];
	$self->Verbose("test: request ".$request->id." input(".$request->input.") ",1);

	my $txt = '';
	my $opt;
	my $sub_command = $request->command->[0];
	my $command = $request->command->[1];

	# break down args
	eval { $opt = Getopt::Lucid->getopt( [
		Param("like"),
		Param("unlike"),
		Param("ok"),
		Param("name"),
		Param("max_lines|l"),
		Param("match_times|t"),
		Param("ttl"),
		Switch('ordered'),
		Switch('cache')->default(1),
		Switch("verbose|v"),
		Switch("feedback|f"),
	], $request->args )};

	if( $@ )
	{
		$self->Verbose('set: getopt lucid got ('.$@.') ');
		$request->Respond($kernel,  "Invalid Args: $@ !", 400);
		return;
	}

   	# Validate args
   	# Need to evolve this into being more automated code but not sure how yet.
   	# Probably should check that like and unlike and ok are not all set at once.
   	# someday....
	$txt .= $self->NotRegex(qr($opt->get_like), "like" );
	$txt .= $self->NotRegex(qr($opt->get_unlike), "unlike");
	$txt .= $self->NotType($opt->get_ok, "ok", qr(code)i);
	$txt .= $self->NotScalar($opt->get_name, "name" );
	$txt .= $self->NotPosInt($opt->get_max_lines, "max_lines");
	$txt .= $self->NotPosInt($opt->get_match_times, "match_times");
	$txt .= $self->NotPosInt($opt->get_ttl, "ttl" );
	$txt .= $self->NotPosInt($opt->get_verbose, "verbose",);
	$txt .= $self->NotPosInt($opt->get_feedback, "feedback",);

	if( $txt )
	{
		$self->Verbose('test: paramter validation failed txt('.$txt.') ');
		$request->Respond($kernel, "Invalid Args: ".$txt, 400);
		return;
	}

	my ($testsub, $expr);

	if ( defined( $opt->get_like ) )
	{
		$expr = $opt->get_like;
		$testsub = sub { $_[0] =~ qr($expr);  };
	}
	elsif ( defined( $opt->get_unlike ) )
	{
		$expr = $opt->get_unlike;
		$testsub = sub { $_[0] !~ qr($expr);  };
	}
	elsif ( defined( $opt->get_ok ) )
	{
		$expr = $opt->get_ok;
		$testsub = $expr ;
	}
	unless ($testsub->($expr))
	{
		$self->Verbose('test: Whoops result is not true!!! ');
		$self->Verbose('test: $expr('.$expr.') result('.$testsub->($expr).') ');
	}

	my $num = $self->depth_test_queue + 1;

	my $name = defined( $opt->get_name ) && $opt->get_name ne ''
		? $opt->get_name
		: 'tail '.$expr;

	my $birthtime = defined( $request->get_time )
		? $request->get_time
		: time();

	my ($match_times, $max_lines, $ttl, $verbose, $feedback, $ordered,
		$cache);
	my $last_line = 0;

	if ( $command eq 'test' )
	{
		$match_times = defined($opt->get_match_times) && $opt->get_match_times ne ''
			? $opt->get_match_times
			: $self->test_match_times;

		$max_lines = defined($opt->get_max_lines) && $opt->get_max_lines ne ''
			? $opt->get_max_lines
			: $self->test_max_lines;

		# max_lines cannot be less than match_times

		$ttl = defined($opt->get_ttl) && $opt->get_ttl ne ''
			? $opt->get_ttl
			: $self->test_ttl;

		$verbose = defined($opt->get_verbose) && $opt->get_verbose != 0
			? $opt->get_verbose
			: $self->test_verbose;

		$feedback = defined($opt->get_feedback) && $opt->get_feedback != 0
			? $opt->get_feedback
			: $self->test_feedback;

		$ordered = $opt->get_ordered || $self->ordered;

	    $cache = defined($opt->get_cache) && $opt->get_cache ne ''
	    	? $opt->get_cache : 1;
	}
	# watch is just test with different defaults.
	elsif ( $command eq 'watch' )
	{
		$match_times = defined($opt->get_match_times) && $opt->get_match_times ne ''
			? $opt->get_match_times
			: 0;

		$max_lines = defined($opt->get_max_lines) && $opt->get_max_lines ne ''
			? $opt->get_max_lines
			: 0;

		$ttl = defined($opt->get_ttl) && $opt->get_ttl ne ''
			? $opt->get_ttl
			: 0;
		# Counters not provided by user are always zero from opt.
		$verbose = defined($opt->get_verbose) && $opt->get_verbose != 0
			? $opt->get_verbose
			: 0;

		$feedback = defined($opt->get_feedback) && $opt->get_feedback != 0
			? $opt->get_feedback
			: 1;

		$ordered = $opt->get_ordered || 0;

	    $cache = defined($opt->get_cache) && $opt->get_cache ne ''
	    	? $opt->get_cache : 0;
	}

	if ( $match_times > $max_lines && ! defined($opt->get_max_lines) )
	{
		$max_lines = $match_times;
		$self->Verbose("test: set max_lines to match_times($match_times)");
	}

	# Set line count to current line so that anything in the line cache will be skipped.
	unless ( $cache )
	{
		$last_line = $self->line_count;
		$self->Verbose("test: cache($cache) last_line($last_line)",1);
	}

	if ($sub_command eq 'add')
	{
		$self->Verbose("test:  args dump \n 'code'	=> $testsub, \n 'name'		=> $name,\n	'num'		=> $num,\n'max_lines'	=> $max_lines,\n'match_times'=> $match_times,\n'ttl'	=> $ttl,\n'verbose'	=> $verbose,\n'feedback'	=> $feedback,\n'handler'	=> 'Check',\n'log_name'\t=> 'Append',\n'ordered'\t=> $ordered,\n'last_line'\t=> $last_line\n ", 3 - $verbose);
		$self->Verbose("test: self dump (".$self->dump(1).") ",4);

		my $test = Agent::TCLI::Package::Tail::Test->new(
			'code'		=> $testsub,
			'name'		=> $name,
			'num'		=> $num,
			'max_lines'	=> $max_lines,
			'match_times'=> $match_times,
			'birth_time'=> $birthtime,
			'ttl'		=> $ttl,
			'verbose'	=> $verbose,
			'feedback'	=> $feedback,
			'handler'	=> 'Check',
			'log_name'	=> 'Append',
			'ordered'	=> $ordered,
			'request'	=> $request,
			'last_line' => $last_line,
		);
		$self->Verbose("test: new test dump (".$test->dump(1).") ",3);

		$self->push_test_queue($test);

		$request->Respond($kernel, "test num=".$num." added", 100);

		# Force activation check now.
		$kernel->call($self->name => 'Activate');
	}
	elsif ($sub_command eq 'delete')
	{
		#I'm very tired....
		# Need to get test num, and mark complete, cause if we delete it
		# it will mess up numbering, but will marking as complete and not
		# returning it suffice?

		# mark complete

		# remove state
	}
	return (1);
}

=item clear

This POE event handler executes the clear command. It is called by the
Control and takes a Request as an argument.

=cut

sub clear {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];
	$self->Verbose("clear: request ".$request->id );

	my ($txt, $subtxt, $what);

	$what = $request->command->[0];

	if ( $what eq 'lines' )
	{
		$txt .= "Removing ".$self->depth_line_cache." lines.";
		$self->set(\@line_cache,[ ]);
		$self->Verbose("clear: ".$txt);
	}

  	if (!defined($txt) || $txt eq '' )
  	{
  		$txt = "Cannot clear ".$what
  	}

	$request->Respond($kernel, $txt, 200);
}

=item file

This POE event handler executes the file commands. It is called by the
Control and takes a Request as an argument.

=cut

sub file {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];

	my $txt = '';
	my $opt;
	my $command = $request->command->[0];

	# break down args
	eval { $opt = Getopt::Lucid->getopt( [
		Param("file")->required(),
		Param("filter"),
		Param("interval"),
		Param("seek"),
		Param("seekback"),
	], $request->args )};

	if( $@ )
	{
		$self->Verbose('file: getopt lucid got ('.$@.') ');
		$request->Respond($kernel,  "Invalid Args: $@ !", 400);
		return;
	}

   	# Validate args
   	# Need to evolve this into being more automated code but not sure how yet.
	$txt .= $self->NotScalar($opt->get_file, "file" );
	$txt .= $self->NotType($opt->get_filter, "filter", qr(POE::Filter));
	$txt .= $self->NotPosInt($opt->get_interval, "interval" );
	$txt .= $self->NotPosInt($opt->get_seek, "seek");
	$txt .= $self->NotPosInt($opt->get_seekback, "seekback");

	if( $txt )
	{
		$self->Verbose('set: paramter validation failed txt('.$txt.') ');
		$request->Respond($kernel, "Invalid Args: ".$txt, 400);
		return;
	}
	elsif ($command eq 'add')
	{
		$kernel->yield( SetFollowTailWheel => {
			'file' 		=> $opt->get_file,
			'filter'	=> $opt->get_filter,
			'interval'	=> $opt->get_interval,
			'seek'		=> $opt->get_seek,
			'seekback'	=> $opt->get_seekback,
			});

		$request->Respond($kernel, "file ".$opt->get_file." added", 200);
	}
	elsif ($command eq 'delete')
	{
		my $wheel = $self->files->{ $opt->get_file }{'wheel'};
		# SetWheel on a wheel ID removes the wheel reference, which
		# should cause it to stop.
		$self->SetWheel($wheel);
	}
	return (1);
}

=item settings

This POE event handler executes the set commands.

=cut

sub settings {  # Can't call it set
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];

	my $txt = '';
	my $opt;
	my $command = $request->command->[0];

	# TODO a way to unset/restore defaults....

	# break down args
	eval { $opt = Getopt::Lucid->getopt( [
		Counter("test_verbose"),
		Counter("test_feedback"),
		Param("ordered"),
		Param("interval"),
		Param("line_max_cache"),
		Param("line_hold_time"),
		Param("test_max_lines"),
		Param("test_match_times"),
		Param("test_ttl"),
	], $request->args )};

	if( $@ )
	{
		$self->Verbose('set: getopt lucid got ('.$@.') ');
		$request->Respond($kernel,  "Invalid Args: $@ !", 400);
		return;
	}

   	# Validate args
   	# Need to evolve this into being more automated code but not sure how yet.
	$txt .= $self->NotPosInt($opt->get_test_verbose, "test_verbose", 'set');
	$txt .= $self->NotPosInt($opt->get_test_feedback, "test_feedback", 'set');
	$txt .= $self->NotPosInt($opt->get_ordered, "ordered", 'set');
	$txt .= $self->NotPosInt($opt->get_interval, "interval", 'set');
	$txt .= $self->NotPosInt($opt->get_line_max_cache, "line_max_cache", 'set');
	$txt .= $self->NotPosInt($opt->get_line_hold_time, "line_hold_time", 'set');
	$txt .= $self->NotPosInt($opt->get_test_max_lines, "test_max_lines", 'set');
	$txt .= $self->NotPosInt($opt->get_test_match_times, "test_match_times", 'set');
	$txt .= $self->NotPosInt($opt->get_test_ttl, "test_ttl", 'set');

	if( $txt )
	{
		$self->Verbose('set: paramter validation failed txt('.$txt.') ');
		$request->Respond($kernel, "Invalid Args: ".$txt, 400);
		return;
	}
	else
	{
		$request->Respond($kernel, 'ok', 200);
	}
}

=item show

This POE event handler executes the show commands. It is called by the
Control and takes a Request as an argument.

=cut
#
# Now handled in base class

=item log

This POE event handler executes the log commands. It is called by the
Control and takes a Request as an argument.

=cut

sub log {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];
	$self->Verbose("log: request ".$request->id." input(".$request->input.") ");

	my $txt = '';
	my $opt;
	my $command = $request->command->[0];

	my $num = $self->depth_test_queue + 1;

	if ($command eq 'log')
	{
		$self->Verbose("log: args dump \n 'name'		=> $request->input,\n	'num'		=> $num,\n'handler'	=> 'Log',\n'log_name'	=> 'Append',\n ",2);
		$self->Verbose("log: self dump (".$self->dump(1).") ",4);


		my $test = Agent::TCLI::Package::Tail::Test->new(
#			'code'		=> $testsub,
			'name'		=> $request->input,
			'num'		=> $num,
#			'max_lines'	=> $max_lines,
#			'match_times'=> $match_times,
			'ttl'		=> 30,
#			'verbose'	=> $verbose,
			'handler'	=> 'Log',
			'log_name'	=> 'Append',
			'ordered'	=> 0,
			'request'	=> $request,
		);
		$self->Verbose("log: new test dump (".$test->dump(1).") ",3);

		$self->push_test_queue($test);
	}
	return (1);
}

sub _preinit :Preinit {
	my ($self,$args) = @_;

	$args->{'name'} = 'tcli_tail';

  	$args->{'session'} = POE::Session->create(
      object_states => [
          $self => [qw(
          	_start
          	_stop
          	_shutdown
          	_default
          	_child

			clear
			establish_context
			file
			log
			show
			test
			settings

			Activate
			Append
			Check
			Complete
			FileReset
			PruneLineCache
			SetFollowTailWheel
			Wally

			)],
      ],
  	);
}

sub _init :Init {
	my $self = shift;

	$self->LoadYaml(<<'...');
---
Agent::TCLI::Parameter:
  name: file
  help: The full Unix path of the file name.
  manual: >
    The full Unix path of the file that will be tailed.
  type: Param
---
Agent::TCLI::Parameter:
  name: filter
  help: Optional POE::Filter.
  manual: >
    A POE::Filter that will be applied by POE::Wheel::FollowTail on the file
    being tailed.
  type: Param
---
Agent::TCLI::Parameter:
  name: interval
  help: Seconds to wait between checks.
  manual: >
    Seconds to wait between checks.
  type: Param
---
Agent::TCLI::Parameter:
  name: seek
  help: Seek forward byte count.
  manual: >
    The Seek parameter tells Tail how far from the start of the file to start
    reading. Its value is specified in bytes, and values greater than the
    file's current size will quietly cause Tail to start from the file's end.
    A Seek parameter of 0 starts FollowTail at the beginning of the file.
    A negative Seek parameter emulates SeekBack: it seeks backwards from
    the end of the file.
    Seek and SeekBack are mutually exclusive. If Seek and SeekBack are not
    specified, Tail seeks 4096 bytes back from the end of the file
    and discards everything until the end of the file. This helps ensure
    that Tail returns only complete records.
  type: Param
---
Agent::TCLI::Parameter:
  name: seekback
  help: Seek backwards byte count.
  manual: >
    The SeekBack parameter tells Tail how far back from the end of the file
    to start reading. Its value is specified in bytes, and values greater
    than the file's current size will quietly cause Tail to start from
    the file's beginning.
    A SeekBack parameter of 0 starts Tail at the end of the file.
    It's recommended to omit Seek and SeekBack to start from the end of a file.
    A negative SeekBack parameter emulates Seek: it seeks forwards from
    the start of the file.
  type: Param
---
Agent::TCLI::Parameter:
  name: name
  help: The name of the test.
  manual: >
    The name is purely cosmetic and will be returned with the test results
    simliarly to the way Test::Simple operates. This might be useful
    when reporting results to a group chat or log.
  type: Param
---
Agent::TCLI::Parameter:
  name: like
  help: A regex to match.
  manual: >
    Like sets a regular expression for the test to match within a line.
    The regex should be either a string
  type: Param
---
Agent::TCLI::Parameter:
  name: line_max_cache
  alaises: max_cache
  constraints:
    - UINT
  help: The maximum number of lines to keep in the line_cache.
  manual: >
    The line_max_cache parameter sets how many lines to keep in the line cache.
    Since actions are asynchronous, it is a good idea to have at least some
    line cache so that a tail test will work when the action to generate the
    log ocurred before the test was in place.
  type: Param
---
Agent::TCLI::Parameter:
  name: line_hold_time
  alaises: hold_time
  constraints:
    - UINT
  help: The time, in seconds, to keep lines in the cache.
  manual: >
    The line_hold_time parameter sets how many seconds to keep lines in
    the line_cache. This is not an exact amount but rather the minimum,
    The purge_line_cache process does not run every second, but lines that
    exceeed the hold_time will be purged when it does run.
  type: Param
---
Agent::TCLI::Parameter:
  name: test_max_lines
  alaises: max_lines
  help: The maximum number of lines to check before failing.
  manual: >
    The max_lines parameter sets how many lines to check before giving up
    and failing. For tests, the default is ten, which is the default size
    of the line cache. This means that by default, a test will only check the
    most recent lines of what is being tailed.
    For watches, the default is zero, which means it does not ever give up.
  type: Param
---
Agent::TCLI::Parameter:
  name: test_match_times
  aliases: match_times
  help: The numer of times the a match must be found.
  manual: >
    The match_times parameter sets how many times a line must match
    in order to pass. For tests, the default is one. For watches, the default is
    zero, which means it ignores match_times and stays active.
  type: Param
---
Agent::TCLI::Parameter:
  name: test_ttl
  aliases: ttl
  help: The time-to-live in seconds.
  manual: >
    The ttl parameter sets how many seconds to wait before giving up
    and failing. For tests, the default is 30. For watches, the default is
    zero, which means it does not ever expire.
  type: Param
---
Agent::TCLI::Parameter:
  name: ordered
  help: Set the order for processing tests.
  manual: >
    Ordered is a boolean switch indicating how to process the tests. If set
    a test will not be checked against a line until the previous test has
    passed. If ordered is off then multiple tests are running, and tests
    are always processed in the order that they were created. The default
    ordered setting is off for both tests and watches.
  type: Switch
---
Agent::TCLI::Parameter:
  name: feedback
  help: Sets the feedback level for what is seen.
  manual: >
    Feedback sets the level of additional information about the line that is
    returned. Currently it is either zero, which is nothing,
    or one, which returns the whole line. Feedback occurs when a line is
    matched or if a test is set for verbose. Feedback is set per test, so
    if multiple tests are active and verbose is one, there is the possibility
    of seeing the same line more than once. This is useful for debugging
    a particular test/watch.
  type: Switch
---
Agent::TCLI::Parameter:
  name: test_verbose
  aliases: verbose|v
  help: Sets the verbosity level for a test.
  manual: >
    Verbose sets the level of additional information about the test that is
    returned. Currently it is either zero, which is nothing,
    or one, which enables feedback (if set) on every line that is seen.
  type: Switch
---
Agent::TCLI::Parameter:
  name: cache
  help: Determines whether the line cache is used.
  manual: >
    The line cache will hold the most recent lines seen. This option determines
    whether to use the line cache or only examine new lines when a test is set.
    The default for tests is on, and for watches is off. To turn off use
    no-cache as a test/watch option.
  type: Switch
---
Agent::TCLI::Parameter:
  name: line_cache
  help: The lines in the cache currently.
  manual: >
    The line cache will hold the most recent lines seen. This will show the
    contents of the line cache.
  type: Switch
---
Agent::TCLI::Parameter:
  name: test_queue
  help: The tests and watches that have been requested.
  manual: >
    The test_queue holds all the tests that have been requested.
    This could be a very long list.
  type: Switch
---
Agent::TCLI::Parameter:
  name: active
  help: The tests and watches that are currently active.
  type: Switch
---
Agent::TCLI::Command:
  name: tail
  call_style: session
  command: tcli_tail
  contexts:
    ROOT: tail
  handler: establish_context
  help: tail a file
  topic: testing
  usage: tail file add file /var/log/messages
---
Agent::TCLI::Command:
  name: file
  call_style: session
  command: tcli_tail
  contexts:
    tail: file
  handler: establish_context
  help: manipulate files for tailing
  topic: testing
  usage: tail file add file /var/log/messages
---
Agent::TCLI::Command:
  name: file-add
  call_style: session
  command: tcli_tail
  contexts:
    tail:
      file: add
  handler: file
  help: designate a file for tailing
  topic: testing
  usage: tail file add file /var/log/messages
---
Agent::TCLI::Command:
  name: file-delete
  call_style: session
  command: tcli_tail
  contexts:
    tail:
      file: delete
  handler: file
  help: delete a tailing of a file
  topic: testing
  usage: tail file delete file /var/log/messages
---
Agent::TCLI::Command:
  name: test
  call_style: session
  command: tcli_tail
  contexts:
    tail:
      - test
      - watch
  handler: establish_context
  help: manipulate tests on tails
  topic: testing
  usage: tail test add like qr(alert)
---
Agent::TCLI::Command:
  name: test-watch-add
  call_style: session
  command: tcli_tail
  contexts:
    tail:
      test: add
      watch: add
  handler: test
  help: add a new tests on the tails
  parameters:
    feedback:
    test_match_times:
    test_max_lines:
    name:
    ordered:
    test_ttl:
    test_verbose:
  topic: testing
  usage: tail test add like qr(alert) <options>
---
Agent::TCLI::Command:
  call_style: session
  command: tcli_tail
  contexts:
    tail:
      test: delete
      watch: delete
  handler: test
  help: delete a test on the tails
  name: test-watch-delete
  topic: testing
  usage: tail test delete num 42
---
Agent::TCLI::Command:
  name: set
  call_style: session
  command: tcli_tail
  contexts:
    tail: set
  handler: settings
  help: adjust default settings
  parameters:
    ordered:
    interval:
    line_max_cache:
    line_hold_time:
    test_max_lines:
    test_match_times:
    test_ttl:
    test_verbose:
  topic: testing
  usage: tail set test_max_lines 5
---
Agent::TCLI::Command:
  name: show
  call_style: session
  command: tcli_tail
  contexts:
    tail: show
  handler: show
  help: show tail default settings and state
  parameters:
    ordered:
    interval:
    line_max_cache:
    line_hold_time:
    test_max_lines:
    test_match_times:
    test_ttl:
    test_verbose:
    test_queue:
    line_cache:
    active:
  topic: testing
  usage: tail show settings
---
Agent::TCLI::Command:
  name: log
  call_style: session
  command: tcli_tail
  contexts:
    tail: log
  handler: log
  help: add text to the line queue
  manual: >
    The log command allows one to add a line of text to the queue. It helped
    to facilitate testing of the tail package, but might not be useful
    otherwise. Still, here it is. Any text following log appears in the line
    queue as if it was coming from a tailed file.
  topic: testing
  usage: tail log "some text"
---
Agent::TCLI::Command:
  call_style: session
  command: tcli_tail
  contexts:
    tail: clear
  handler: establish_context
  help: clears out a cache
  name: clear
  topic: testing
  usage: tail clear lines
---
Agent::TCLI::Command:
  call_style: session
  command: tcli_tail
  contexts:
    tail:
      clear: lines
  handler: clear
  help: clears out the line cache
  name: clear_lines
  topic: testing
  usage: tail clear lines
...

}

=item _shutdown

This POE event handler is used to initiate a shutdown of the Package.

=cut

sub _shutdown :Cumulative {
	my ($kernel,  $self,) =
      @_[KERNEL, OBJECT,];
	$self->Verbose("_shutdown:tail ".$self->name." shutting down");

    return;
}

=item _start

This POE event handler is called when POE starts up a Package.
The B<_start> method is :Cumulative within OIO.

=cut

sub _start {
	my ($kernel,  $self,  $session) =
      @_[KERNEL, OBJECT,   SESSION];
    $self->Verbose("_start: Starting test_tail ");

	# are we up before OIO has finished initializing object?
	if (!defined( $self->name ))
	{
		$kernel->yield('_start');
		return;
	}

	# There is only one command object per TCLI
    $kernel->alias_set($self->name);

	$kernel->delay('PruneLineCache',10);
	$kernel->delay('Activate', $self->interval , 0 );

	return("_start ".$self->name);
}

1;
#__END__

=back

=head3 INHERITED METHODS

This module is an Object::InsideOut object that inherits from
Agent::TCLI::Package::Base. It inherits methods from both.
Please refer to their documentation for more details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

Currently there is no separation between users running tests, which means it
could be very ugly to have multiple users try to run tests on one TCLI Agent.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

