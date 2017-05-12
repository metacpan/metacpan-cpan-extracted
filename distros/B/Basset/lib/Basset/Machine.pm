package Basset::Machine;

#Basset::Machine, copyright and (c) 2004, 2005, 2006 James A Thomason III
#Basset::Machine is distributed under the terms of the Perl Artistic License.

=pod

=head1 NAME

Basset::Machine - used to state machines

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 DESCRIPTION

Basset::Machine implements a state machine. This is useful for any thing that requires a process flow.
web applications, shell scripts, tk apps, you name it. Anything that you want that requires user
interaction and a flow of control.

=head1 SYNOPSIS

An example is best. Let's try a simple one.

 package My::Machine;
 use Basset::Object;
 Basset::Object->inherits(__PACKAGE__, 'machine');
 
 sub start {
 	return shift->state('login');
 }
 
 sub login {
 	my $self = shift;
 	my $heap = $self->heap;
 	
 	if ($heap->{'loggedin'}) {
 		return $self->state('success');
 	} else {
 		return $self->state('prompt');
 	}
 }
 
 sub prompt {
 	my $self = shift;
 	print "Please enter your username (must be 'bob'): ";
 	chomp(my $name = <STDIN>);
 	
	$self->{'heap'}->{'loggedin'} = 1 if $name eq 'bob';
 	return $self->state('login');
 }
 
 sub success {
 	my $self = shift;
 	
 	print "You are logged in\n";
 	
 	return $self->terminate;
 }
 
 1;
 
 ---
 
 #!/usr/bin/perl
 use My::Machine;
 
 My::Machine->execute;

Look at the L<http://www.bassetsoftware.com/perl/basset/tutorial> for more info.

=cut

use strict;
use warnings;

our $VERSION = '1.01';

use Basset::Object;
our @ISA = Basset::Object->pkg_for_type('object');

=pod

=head1 ATTRIBUTES

=over

=item state

This is the current state of the machine. This is how you move around in the flow of your
machine. The default start state is 'start'. If you don't provide a state when your machine
starts executing, it will try to enter the start state. You may always provide the state that you
want. It is traditional to return the next state from your current state.

 sub current_state {
 	my $self = shift;
 	
 	return $self->state('next_state');
 }

States are usually methods in your machine module. But, if you have a complicated state, you may
put it into its own class, in a subdirectory of the Machine class. methods in the machine class take
precedence over external states. External states are entered via their 'main' method.

 package My::Machine;
 
 sub some_state {
 	return shift->state('login');
 }
 
 package My::Machine::Login;
 
 sub main {
 	my $self = shift;
 	my $machine = $self->m;
 	
 	return $self->m->state('jump_pt');
 }

All machines implicitly start in a setup state when they begin running, and end with a terminate state,
if those are defined. Note that these states will be entered any time the machine starts or stops running,
respectively, so you may need to explicitly check the current state as appropriate.

When entering a state, you receive 1 argument - the state you came from. You may receive additional
arguments that the prior state handed in to you.

See Basset::Machine::State for more information.

=cut

__PACKAGE__->add_attr('_state');

sub state {
	my $self = shift;
	
	if (@_) {
		my $last = $self->_state;
		$self->_state(shift);
		return ($last, @_);
	}
	
	return $self->_state;
}

=pod

=item heap

The heap is a hashref that contains useful information that's local to the machine. You can
think of it as a global namespace as far as the states are concerned, but local to the machine.

This is how data is passed from state to state.

 sub state1 {
 	my $self = shift;
 	$self->heap->{'value1'} = 'foo';
 	
 	return $self->state('state2');
 }
 
 sub state2 {
 	my $self = shift;
 	
 	print 'value1 is ', $self->heap->{'value1'}, "\n";
 
 	return $self->terminate;
 }

=cut

__PACKAGE__->add_attr('heap');

#Boolean flag. This determines if the machine is currently running. It's automatically set as
#the machine starts and stops. You should never need to worry about it.

__PACKAGE__->add_attr('running');

=pod

=item transitions

transitions provides a layer of insulation for you. Instead of explicitly specifying your 
machine's states in code (for example, in a web app where every html page needs to return the
machine's state), you can instead define a transition. This allows you to hide the actual states
from the external world. So you can re-define states as desired, but the transitions will always
remain the same.

 My::Machine->transitions({
 	'login' => 'login_prompt',
 	'analyze' => 'analyze_2',	#changed from old 'analyze' method
 });

You then invoke it via a transition call, instead of a state call.

 sub state {
 	my $self = shift;
 	
 	return $self->transition('analyze');
 }

=cut

__PACKAGE__->add_trickle_class_attr('transitions', {});

=pod

=item reentry_is_fatal

object attribute, which defaults to true. Normally, this will prevent you from re-entering
a state from itself. Most of the time, this means that you forgot to transition out of it 
at the end of the state.

Nonetheless, there are times when you may want to stay where you are. If you have a machine
that functions that way, then make this attribute false, and best of luck to you.

=back

=cut

__PACKAGE__->add_attr('reentry_is_fatal');

=pod

=item extractor

Most machines tend to need extractors. So you have one for free here. Wrappered by the extract method, below.

=cut

__PACKAGE__->add_attr('extractor');

=pod

=begin btest(extractor)


=end btest(extractor)

=cut


sub init {
	return shift->SUPER::init(
		'running'		=> 0,
		'heap'				=> {},
		'state'				=> 'start',
		'reentry_is_fatal'	=> 1,
		@_
	);
}

=pod

=head1 METHODS

=over

=item execute

convenience method which allows you to create and run a machine in one step.

 My::Machine->execute();
 
is the same as:

 my $m = My::Machine->new();
 $m->run();

Will return undef if the machine aborts or is not constructed, and the machine itself upon its
termination.

=cut

sub execute {
	my $class = shift;
	my $m = $class->new(@_) or return;
	
	$m->run() or return $class->error($m->errvals);
	
	return $m;
}

=pod

=item run

Actually runs the machine, transitions states, does all the magic.

 $machine->run;

=cut

sub run {
	my $self = shift;

	$self->running(1);

	my @rc = (undef); #that way, the start state will always reflect that it came from nothing.

	$self->setup or $self->abort;

	while ($self->running) {
		my $state = defined $self->state ? $self->state : 'start';
		if ($self->can($state)) {
			@rc = $self->$state(@rc) or return;
		} else {
			my $state_pkg = $self->pkg . "::" . ucfirst($state);
			if (ref $state eq 'ARRAY') {
				($state, $state_pkg) = @$state;
			}
			
			$self->load_pkg($state_pkg) or return $self->abort("Cannot jump to $state : not defined (" . $self->error . ")", $self->errcode);
			
			my $state_obj = $state_pkg->new();
			$state_obj->machine($self);
			@rc = $state_obj->main(@rc) or return $self->abort($state_obj->errvals); 
		}
		
		#if reentry is fatal, and we haven't moved (same state, or still at start, we bomb)
		if (((defined $self->state && $state eq $self->state) || ($state eq 'start' && ! defined $self->state)) && $self->reentry_is_fatal) {
			return $self->abort("Attempted to re-enter $state. Did you forget to transition?", "BM-07");
		}
			
	}
	
	$self->teardown or return;
	
	return wantarray ? @rc : $rc[0];
	
}

=pod

=item setup

implicit state that executes when the machine starts running. Does not actually affect the current
state of the machine (that is, you can check $self->state and it won't return 'setup'). By default,
it just returns success and the machine then begins running.

This is a good place to do things like setup database connections, look up frequently used classes,
cache data, etc. By default, you get your extractor attribute set to whatever's in your conf file.

If setup aborts, it will teardown the machine and nothing will run.

=cut

sub setup {
	my $self = shift;
	
	$self->extractor($self->pkg_for_type('extractor'));
	
	return $self;
}

=pod

=item teardown

implicit state that executes when the machine stops running. Will receive no arguments if the machine
terminates normally (terminate or interrupt), will receive the single word "aborted" if the machine is stopping due to an abort.
Does not actually affect the last run state (that is, you can check $self->state and it won't return
'teardown'). By default, it just returns success and the machine is done running.

This is a good place to do things like close database connections, write things to disk, log messages,
etc.

=cut

sub teardown {
	return 1;
}

=pod

=item start

start is the only state that must be defined within the machine class itself. This super method is
abstract and aborts the machine. You must override it.

=cut

sub start {
	my $self = shift;
	
	return $self->abort("Cannot enter start state : not defined", "BM-01");
}

=pod

=item terminate

terminate stops the machine normally and clears out the current state.

=cut

sub terminate {
	my $self = shift;

	$self->running(0);
	$self->state(undef);
	
	return 'terminated';
}

=pod

=item interrupt

interrupt expects to be given a state. It will stop the machine from running, and advance it to
the state that was provided. This is useful to temporarily suspend the machine and return to it
later. Note that re-running the machine will cause setup to be re-run, and that you will still
run teardown after the interrupt.

=cut

sub interrupt {
	my $self = shift;
	my $state = shift or return $self->abort("Cannot interrupt w/o next state", "BM-02");
	
	$self->state($state);
	
	$self->running(0);
	
	return $state;
}

=pod

=item abort

aborts the machine immediately, tears it down, and returns the error passed in. This should be
used to report machine errors in place of ->error.

=cut

sub abort {
	my $self = shift;
	$self->teardown('aborted') or return;
	return $self->error(@_);
}

=pod

=item machine

simply returns self. This is a convenience method to make states more readily interchangeable between
methods and explicit state modules

=cut

sub machine {
	return shift;
}

=pod

=item transition

transitions the machine to the next state, as per the transitions table.

 $m->transition('login');

=cut

sub transition {
	my $self = shift;
	my $key = shift or return $self->abort("Cannot transition w/o key", "BM-03");	
	
	my $next_state = $self->transitions->{$key}
		or return $self->abort("Cannot transition: no state jump for key $key", "BM-05");

	return $self->state($next_state, @_);
}

=pod

=item extract

Convenience method. Simply calls extract on your extractor attribute, if you have one.

=cut

sub extract {
	my $self = shift;
	my $extractor = $self->extractor or return $self->error("Cannot extract w/o extractor", "XXX");
	
	return $extractor->extract(@_) or $self->error($extractor->errvals);
}

=pod

=begin btest(extract)

=end btest(extract)

=cut


=pod

=back

=cut

1;
