package DFA::Simple;

use strict;
use warnings;
use Carp;

our $VERSION = "0.34";

# XXX: looks more like an instance variable
my $CurrentStateTable = [];

=head1 NAME

DFA::Simple - A Perl module to implement simple Discrete Finite Automata

=head1 SYNOPSIS

   my $Obj = new DFA::Simple

or

   my $Obj = new DFA::Simple $Transitions;

or

   my $Obj = new DFA::Simple $Actions, $StateRules;

   $Obj->Actions = [...];
   my $Trans = $LP->Actions;

   $Obj->StateRules = [...];
   my $StateRules = $LP->StateRules;


=head1 DESCRIPTION

   my $Obj = new DFA::Simple $Actions,[States];

This creates a simple automaton with a finite number of individual states. 
The short version is that state numbers are just indices into the array.

The state basically binds the rest of the machine together:

=over 8

=item 1. There might be something you want done whenever you enter a given state (Transition Table)

=item 2. There might be something you want done whenever you leave a given state (Transition Table)

=item 3. You can go to some states from the current state (Action table)

=item 4. There are tests to decide whether you should go to that new state (Action table)

=item 5. There are conditional tasks you can do while sitting in that new state (Action table)

=back

This structure may remind you of the SysV run-level concepts. 
It is very similar.

At run time you don't typically feed any state numbers to the finite machine;
you ignore them.  Rather your program may read inputs or such.  The tests for
the state transition would examine this input, or some other variables to
decide which new state to go to.  Whenever your code has gotten enough input,
it would call the C<Check_For_NextState()> method.  This method runs through
the tests, and carries out the state transitions ("firing the rules").

=head2 The State Definitions, Tests, and Transitions

As for where the state definitions, tests, and transitions come from: you have
to define them yourself, or write a program to do that.  There are techniques
for converting Phase Structure grammars into state machines (usually thru
converting it to Chomsky Normal form, and such), or by drawing bubble diagrams.
In the case of the bubble diagram, I usually just number each bubble
sequentially from left to right.  The arc (and its condition) will tell me most
of how to build the Action Table.  What the bubble is supposed to do will tell
me how to build the Transition Table and the last column of the Action Table.

To support these, the object is composed of the following three things (with
methods to match):

=over 1

=item I<State>

The object has a particular state it is in; a specific state from a set of
possible states

=item I<Actions>

The object when entering or leaving a state may perform some action.

=item I<Rules>

The object has rules for determining what its next state should be, and how to
get there.

=back

=head2 Example

Before we get into the deep details, I'll present a quick example.  First,
here is the output:

	[randym@a Out]$ perl tmp.pl
	Intro

	I will force us to silently go to state 1, then 2, then 3:
	Greetings
	Am Here (in state 1)
	Bye
	Am Here (in state 3)

	Resetting:
	Intro
	I will force us to fail to go to a new state:
	Unusual circumstances?
	 at tmp.pl line 54


And here is the example code:

   use DFA::Simple;

   #A table of what to do when entering or leaving a state.
   my $Transitions =[
	#Say "Intro" when entering state; do nothing when leaving
        [sub {print "Intro\n";}, undef],

	#Say "Greetings" when entering state, do nothing when leaving
        [sub {print "Greetings\n";}, undef],

	#When entering, do nothing, when leaving do nothing
        [undef,undef],

	#When entering say "Bye", when leaving do nothing
        [sub {print "Bye\n";}, undef],
   ];


   # A global variable
   my $BogusTest=0;

   # Our state table.  
   my $States =[
     #State #0
      [
	#Next State,  Test that must be true or return true if we are to go
	#into that state, what we do while /in/ that state
	[1, sub{$BogusTest}, sub{print "Am Here (in state 1)\n"}],

	#We can't go to any other state
      ],

     #State 1
      [
	# We can go to state #2 from state #1 if the test succeeds, but we
	# don't really do anything there
	[2, sub{$BogusTest}, ],
      ],

     #State 2
      [
	#We can go to state #1 again, but we do nothing
	[1, sub{$BogusTest}, ],

	# If the above test(s) fail, the undef below will force us to go
	# into state #3
	[3, undef, sub {print "Am Here (in state 3)\n";}],
      ],
     ];

   my $F=new DFA::Simple $Transitions, $States;
   $F->State(0);

   print "\nI will force us to silently go to state 1, then 2, then 3:\n";
   $BogusTest=1;
   #Drive the state machine thru one transition
   $F->Check_For_NextState();
   #Drive the state machine thru one transition
   $F->Check_For_NextState();

   #Force us to go to state 3
   $BogusTest=0;
   #Drive the state machine thru one transition
   $F->Check_For_NextState();

   print "\nReseting:\n";
   $F->State(0);
   print "I will force us to fail to go to a new state:\n";
   $BogusTest=0;
   $F->Check_For_NextState();


=head2 State

C<State> is a method that can get the current state or initiate a transition to
a new state.

   my $S = $Obj->State;

   $Obj->State($NewState);

The last one leaves the current state and goes to the specified I<NewState>.
If the current state is defined, its I<StateExitCodeRef> will be called (see
below).  Then the new states I<StateEnterCodeRef> will be called (if defined)
(see below).  Caveat, no check is made to see if the new state is the same as
the old state; this can be used to `reset' the state.

=head2 Actions

C<Actions> is a method that can set or get the objects list of actions to
perform when entering or leaving a particular state.

   my $Actions = $Obj->Actions;

   $Obj->Actions([
		   [StateEnterCodeRef, StateExitCodeRef],
		 ]);

   
I<Actions> is an array reference describing what to do when entering and
leaving various states.  When a state is entered, its I<StateEnterCodeRef>
will be called (if defined).   When a state is left (as in going to a new
state) its I<StateExitCodeRef> will be called (if defined).


=head2 StateRules

   my $StateRules = [
		     #Rules for state 0
		     [
		      [NextState, Test, Thing to do after getting there
		      ],

		     #Rules for state 1
		     [
		      ...
		      ],
		     ];

The I<StateRules> is a set of tables used to select the next state.  For the
current state, each item in the table is sequentially examined.  Each rule has
a test to see if we should perform that action.  The test is considered to have
`passed' if it is undefined, or the coderef returns a true.  The first rule
with a test that passes is used -- the state is changed, and the action is
carried out.

The next section describes a different method of determining which rule to 
employ.

=head2 Running the machine

To operate the state machine, first prime it:

	$Obj->State(0);

Then tell it run a state transition:

	$Obj->Check_For_NextState();


=head1 AUGMENTED TRANSITION NETWORKS

The state machine has a second mode of operation -- every rule with a test that
passes is considered.  Since this is nondeterministic (we can't tell which rule
is the correct one), this machine also employs special I<rollback> mechanisms
to undo choosing the wrong rule.  This type of state machine is called an
'Augmented Transition Network.'

For the most part, augmented transition networks are just like the state
machines described earlier, but they also have two more tables (and four more
registers). 

=over 1

=item I<State Stack>

You can push a stack onto the stack, or pop one off.  The register frame is
saved and restored as well.

=item I<Registers>

The object has the method for storing and retrieving information about its
processing.  Everything that you may want to have undone should be stored here.
When the state machine decides it won't undo anything, then it can pass the
information to the rest of the system.

=back

=head2 The State Stack

    $Obj->Hold;
    $Obj->Retrieve;
    $Obj->Commit;

The nondeterminancy is handled in a guess and back up fashion.
If more than one transition rule is possible, the current state (including
the registers) is saved.  Each of the possible transition rules is run; if it
executes C<Retrieve>, the current state will be retrieved, and the next eligible
transition will be attempted.

=over 1

=item C<Hold> will save the current state of the automaton, including the
registers.

=item C<Retrieve> will restore the automaton's previously saved state and
registers.  This is called by a state machine action when it realizes that it
is in the wrong state.

=item C<Commit> will indicate that the previous restore is no longer needed, no
more backtracks will be performed.  It is called by a state machine action that
is confident that it is in the proper state.

=back

=head2 Register

   $Obj->Register->{'name'}='fred';

C<Register> is a method that can set or get the objects register reference.
This is a information that the actions, conditions, or transitions can employ
in their processing.  The reference can be anything.  

C<Register> is important, since it is the automatons mechanism for undoing
actions.  The data is saved before a questionable action is carried out, and
tossed out when a C<Retrieve> is called.  It is otherwise not used by the
object implementation.

=head1 DESIGNING RECURSIVE AND AUGMENTED TRANSITION NETWORKS

There are several issues involved with designing ATNs:
* Input and Output

=head2 Input

All input should be carefully thought out in an ATN -- this is for two reasons:

=over 1

=item * ATNs can back-up and retry different states, and

=item * In multithreaded environments, several branches of the ATN may be
simultaneously operating.

=back

Some things to watch out for: reading from files, popping stuff off of global
lists, things like that.  The current file position may change unexpectedly.


=head2 Output

All IO should be carefully thought out in an ATN -- this is because ATNs can
back-up and retry different states, possibly invaliding any of the ATNs
results.  

print or other file writes
any commands that affect the system (link, unlink, rename, etc.)
C<enqueue> or otherwise changing any Perl variable.

All output should be an ATN decides to commit to a branch

=head2 Following all paths: special issues

If you choose the option of having all the possible paths taken, there are some special issues.
First: what will the new state and registers be?
In this case, the registers are must all be.

Be careful in single commit ATNs, with several nested branches.
These can lead to very inefficient scenarios,
due to the difficulty stop all of the branches of investigation.


=head1 INSTALLATION

Install this module using CPAN, cf. L<How to install CPAN modules|https://www.cpan.org/modules/INSTALL.html>

=head1 AUTHOR

Randall Maas

Maintenance by Alexander Becker (L<asb@cpan.org>)

=cut

#The structure of the node is:
#[CurrentState,Flags,Transitions,States, ...]

sub new
{
    my $self = shift;
    my $class = ref($self) || $self;

    my $B = [];

    #Preserve old state and such
    if (ref $self) 
    {
        @{$B}=@{$self};
    }

    if (@_) {$B->[2]=shift;}
    if (@_) {$B->[3]=shift;}
    if (@_) {$B->[4]=shift;}
    return bless( $B, $class );
} # /new



sub Actions
{
    my $self = shift;

    if (@_)
    {
        #Called to set the actions
        $self->[2] = shift;
    }
    
    $self->[2];
} # /Actions

sub State
{
    my $self=shift;

    my $CState=$self->[0];

    if (!@_)
    {
        #Caller is just getting some info;
        return $CState;
    }

    my $Acts = $self->Actions;
    if (!defined $Acts)
    {
        croak "DFA::Simple: No transition actions!\n";
    }

    if (!defined $self->[3])
    {
        croak "DFA::Simple: No states defined!\n"; 
    }

    my $NS = shift;
    $CurrentStateTable=$self->[3]->[$NS];
    $self->[0]=$NS;

    #Handle the state exit rule
    if (defined $CState && defined $Acts->[$CState])
    {
        my $A;
        if (defined $Acts->[$CState]->[1])
        {
            $A = $Acts->[$CState]->[1];
        }
        elsif (defined $Acts->[$CState]->[2])
        {
            $A = $Acts->[$CState]->[2];
        }
        $A->($self) if defined $A;
     }

    #Handle the transition rule...
    if (defined $Acts->[$NS]->[0])
    {
        my $A = $Acts->[$NS]->[0];
        &$A($self); # XXX: use $A->($self);?
    }
}

sub Check_For_NextState
{
    my $self = shift;
    if (!defined($self->[0]))
    {
        $self->State(0);
    }

    foreach my $I (@{$CurrentStateTable})
    {
        #Perform the test
        if (defined $I->[1])
        {
            my $CodeRef=$I->[1];
            if (!&$CodeRef($self)) {next;}
        }

        #Set up for the next state;
        if ($self->[0] ne $I->[0])
        {
            $self->State($I->[0]);
        }

        #Do the rules
        if (defined $I->[2]) {
            &{$I->[2]}();
        }
      
        return; 
    }
    
    croak "Unusual circumstances?\n";
}

#Child ATN, used to investigate possible branch paths
sub Child
{
    my $self=shift;
    my $ARef=shift;

    #Setup up pointer to where our results go
    $self->[5]=shift;

    #Setup commit/rollback flags to indicate nothing yet
    $self->[1] |= 12;

    #Check to see if the other side has comitted...
	   
    #Set up for the next state
    my $NState=shift;
    if ($self->[0] ne $NState)
    {
        $self->State($NState);
    }
    #Carry out the action coderef;
    if (defined $ARef) {
        $ARef->($self);
    }
   
    #Run the state machine
    $self->NextState();
   
    #Return value
    # 0 or undef if the "abort" (or retrieve previous state) flag is set
    # otherwise, results are good
    return 1 if ($self->[1] & 4);
    return undef;
}

sub Register
{
    my $self = shift;

    if (@_)
    {
        #Called to set the actions
        $self->[4] = shift;
    }
    $self->[4];
}

sub Hold
{
    my $self=shift;
    #Save the state and frame
    push @{$self->[5]}, $self->State, [@{$self->Register}];
}

sub Retrieve
{
    my $self=shift;
    #Check the flags see if we are in threaded mode
    if ($self->[1] & 1)
    {
        #Set the flags to indicate a "Retrieve" operation 
        $self->[1] &= ~4;
        return;
    }
    
    #Otherwise, we are in a mode where we explicitly handle saving and restoring
    #state.
    $self->Register = pop @{$self->[5]};
    $self->State(pop @{$self->[5]});
}

sub Commit
{
    my $self=shift;
    my $CtlVar=$self->[5];
    
    #Indicate that no more processing in this thread should be done
    $self->[1] &= ~8;
    
    #Lock it to prevent someone else from getting there
    lock($$CtlVar);
    
    #Set up the stuff
    $CtlVar->[0] = $self->[0];
    $CtlVar->[1] = $self->[4];
}

1;