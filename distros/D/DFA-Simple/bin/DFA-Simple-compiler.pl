#!/usr/bin/perl -w
#Copyright 1998-1999, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#Perl itself.  

######################################################################
# WARNING ############################################################
######################################################################
# This script is outdated and might not work any longer.             #
# Patches welcome.                                                   #
######################################################################

=head1 NAME

DFA-Simple-compiler -- A simple automaton compiler with discrete states

=head1 DESCRIPTION

This compiles a table of information into a simple automaton.  The automaton
produced is a Perl module that inherits from L<DFA::Simple>.  This is modeled
on augmented transition networks (ATN), but is not as sophisticated.

The options include:

=over 1

=item C<--package >NAME

This specifies the package name of the compiled automaton.

=back

=head1 Description of the simple state machine

A discrete finite automaton is a simple "state" machine that has a limited
number of states (or modes).  The machine behaves differently depending on
which state it is in.  The machine usually starts of in an initial state, and
may have a special state to "shut it off."  

Any time the state is changed, an action may be performed. The next state is
determined by performing a  number of tests.  The first test that passes
indicates what the next state should be, and the action that should be
performed.  The test must be carefully designed to operate correctly; there is
built-in method of recovery after transitioning to the wrong state or
performing the wrong action.  For an automaton that can do this, see ATN
section of L<DFA::Simple>.

To define the automaton, you need to create a file that contains your
definition.  It has three sections, which can be broken down and rearranged
to your liking.  But first, I need to describe comments. A comment is
anything between a C<#> and the end of the line:

   # My comment: hi world!

=head2 Production rules

As I mentioned above, there are three sections: flow based transitions, 
exceptional transitions, and what needs to be done for every transition.  If
you want to describe some transitions based upon the flow of discourses, you
would first start with:

   [productions]

This simply tells the compiler that you will now be defining some production
rules. A production rule looks like:

   CurrentState:NextState:Requires:Test:WhatToDo

or, think of it as a trip

   Here:There:With:Why:How

The production rule is only used if, the I<Here> and I<Why> rules match:

=over 1

=item 1. The discourse state machine is currently in a state that matches I<CurrentState>

=item 2. The I<Test> passes.

=back

That is it.  I<Test> is not simply a pass or fail test.  It does report
whether or not things pass, but it does something more.  Computers process
things very quickly when their facts, parameters, etc. are all lined up and
properly prepared.  And computers can be very fast if they extract this stuff
while they are testing patterns.  So I<Test> can also grab the minutae if it
wants.  On the flip side, I<Test> is optional: not specifying a test is the
same as specifying at test that always passes.

Assuming the test does pass, the discourse machine sets things for what to
do next -- the I<NextState> and the I<WhatToDo>.  These aren't hidden in one
thing, but are kept separate for very good reasons.  They are also optional.
The reason is that a more powerful, faster, and (ironically) testable machine
can be built if the specific next state is declared separately from the
broader I<WhatToDo> declaration.  In other words, you will be arranging
things a way that compiler clearly (or more clearly than otherwise)
understands your goal.  But you need a goal to be understood properly!

=head2 Exceptional rules

There is second section for rules that do not need any tests.  These rules
are "rarely" used -- that is, the production rules are used several dozen or
several hundred times during normal operation, while the exceptional rules are
used once or so.

   [exceptions]
   exceptionname:NextState:WhatToDo

I<WhatToDo> and <NextState> are the same as mentioned in the previous section.
I<ExceptionName> varies -- there are the signals that a program may receive
from the operating system:

=over 1

=item C<SIG.QUIT>,

=item C<SIG.>,

=item  etc.

=back

There is no test, because when the exception is raised, it has been raised.
There is no current state test, because the exceptions can happen in any state.

=head2 Things to do during a transition

    [transition]
    State:ToDoWhenEntering:ToDoWhenLeaving

When the state machine is executing a rule, and the next state is different
from the current state, the following happens:

=over 1

=item 1. The stuff for leaving the current state (I<ToDoWhenLeaving>) is done

=item 2. The matching rule is executed

=item 3. The stuff for entering the next state (I<ToDoWhenEntering>) is done.

=back


=head1 Installation

    perl Makefile.PL
    make
    make install

=head1 Author

Randall Maas (L<randym@acm.org>)

=cut

use Getopt::Long;
my %MyArgs;

GetOptions(\%MyArgs, "package=s");


if (exists $MyArgs{'package'})
{
    print "package $MyArgs{'package'};\n";
}

use Safe;
my $Helper = new Safe;
$Helper->permit(qw(:default));
print "use DFA::Simple;\n\@ISA=qw(DFA::Simple);\n";

my $F=\*STDIN;

my $State=1;
my @States;
my %StateNum;
my $StateCnt=0;
my @Trans;
my $Test_Scanner;

my @ParseState =
(
    undef,undef,
     
    #State == 2
    sub {
        #@_=(This state, next state, test, do);

        #Possibly allocate 'this state'
        if (!exists $StateNum{$_[0]})
        {
            $StateNum{$_[0]}=$StateCnt++;
        }

        #Possibly allocate 'the next state'
        if (!exists $StateNum{$_[1]})
        {
            $StateNum{$_[1]}=$StateCnt++;
        }

        #Build the state rule.
        my ($TSub,$DSub)=('','');
        if (defined $_[4])
        {
            # Attempt to make the things work out
            $_[4] =~ s/(^|[^>\w\$])(?!if)(\w+\()/$1$2/g;
            $DSub="sub {$_[4];}";
        }

        if (defined $_[3] && length $_[3])
        {
            # Attempt to make the things work out
            $_[3] =~ s/(^|[^>\w\$])(?!if)(\w+\()/$1$2/g;
            if (defined $Test_Scanner)
            {
                $_=$_[3];
                $Helper->reval($Test_Scanner);
                if ($@) {die "Test scanner: $@\n";}
                $TSub=$_;
            }
            else
            {
                $TSub=$_[3];
            }
        }
        else
        {
            $TSub="undef";
        }

        $StateRules[$StateNum{$_[0]}] .= "\t[$StateNum{$_[1]}, $TSub, $DSub],\n";
    },

    #State == 3;
    sub {
        my $Sub="sub { ";

        #Part of code for rule transition
        if (defined $_[1])
        {
            if (!exists $StateNum{$_[1]})
            {
                $StateNum{$_[1]}=$StateCnt++;
            }

            $Sub .= $MyArgs{'package'}."->NextState($StateNum{$_[1]});";
        }

        #Part of code for working
        if (defined $_[2])
        {
            $Sub .= $_[2];
        }

        $Sub.="}";

        if ($_[0] =~ /(\w+)\.(\w+)/)
        {
            print "\$$1\{$2}\t= $Sub;\n";
        }
        else
        {
            print "\$Except{$_[0]}=$Sub;\n";
        }
    },

    #State==4
    sub {
        return if !defined $_[0];
        $Trans[$StateNum{$_[0]}]=[$_[1],$_[2]];
     },

    #State == 5, build up a test scanner
    sub {
        #Basically append this to the test scanner code
        $Test_Scanner .= "$_\n";
    }
);


#The file parser
while (<$F>)
{
    chomp;
    
    #Check for POD
    if ($State != 0 && /^=\w+/) {push @States,$State; $State=0; next;}
    
    if ($State==0)
    {
        if (/^=cut\s*$/i) {$State=pop @States;}
        next;
    }
  
    # Work on some other stuff 
    # Remove comments
    s/#.*$//;
    
    # Remove spaces
    s/^\s+//;
    s/\s+$//;
    
    if (!$_ || !length $_) {next;}
    
    #Handle multi-line things
    #   if (/\\$/)
    
    if (/\[productions\]/i)    {$State=2; next;}
    if (/\[exceptions\]/i)     {$State=3; next;}
    if (/\[transition\]/i)     {$State=4; next;}
    if (/\[test\s+scanner\]/i) {$State=5; $Test_Scanner=undef; next;}
    if (/^\[/) {die "Unknown brace\n";}
    
    my $Func= $ParseState[$State];
    &$Func(split(/\s*:\s*/, $_));
}

close $F;

#Now print out the compiled form of the rules...

print "\n\n\nmy \$Transitions =[\n";
foreach my $I (@Trans)
{
    print "\t[";
    if (defined $I)
    {
        if (defined $I->[0] && length $I->[0])
        {
            #Attempt to make the things work out
            $I->[0] =~ s/(^|[^>\w\$])(?!if)(\w+\()/$1$2/g;
    
            print "sub {",$I->[0],";}, ";
        }
        else
        {
            print "undef, ";
        }
    
        if (defined $I->[1] && length $I->[1])
        {
            #Attempt to make the things work out
            $I->[1] =~ s/(^|[^>\w\$])(?!if)(\w+\()/$1$2/g;
   
            print "sub {",$I->[1],";}],\n";
        }
        else
        {
            print "undef],\n";
        }
    }
    else
    {
        print "undef,undef],\n";
    }
}
print "   ];\n";

print "\n\n\nmy \$States =[\n";
for (my $I = 0; $I < scalar @StateRules; $I++)
{
    #Now print the state table for this state.
    print "   [\n$StateRules[$I]\n   ],\n\n";
}
print "  ];\n\n";

# --- Class Constructors ------------------------------------------------------
print "\nsub new\n{\n",
    "   my \$self=shift;\n",
    "   return Lingua::Protocol::new(\$self,\$Transitions,\$States,\@_);\n}\n";
