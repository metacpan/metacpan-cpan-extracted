#!/usr/bin/perl

#-----------------------------------------------------------
# fix_bullets.pl - convert text bullets to HTML lists
# 08/19/04  Bill Ruppert
#-----------------------------------------------------------

use strict;
use warnings;
use Carp;
use lib "./../lib";
use DFA::Simple;

#-----------------------------------------------------------
# Define state names as manifest constants.
# 
# After this, only the state names are used, never the 
# number. All arrays entries are via these numbers, never by 
# implicit positioning.
# 
# Randomizing these numbers has no effect on the program. 
# They do not need to be consecutive nor even ordered. Of 
# course, very large values will cause Perl to create very 
# big sparse arrays.
#-----------------------------------------------------------

use constant {
    stStart     => 0,
    stItem      => 1,
    stSubItem   => 2,
    stEnd       => 3,
};

#-----------------------------------------------------------
# Subroutine prototypes
#-----------------------------------------------------------

sub start_list();
sub end_list();
sub error_start();
sub start_sublist();
sub end_sublist();
sub start_item();
sub end_item();
sub output_subitem();

#-----------------------------------------------------------
# Open output log for debugging
#-----------------------------------------------------------

my $logname = "fix_bullets.log";
open LOG, "> $logname" or croak "Unable to open $logname";

#-----------------------------------------------------------
# $done is set when eof has been reached and can be tested
# by transitions.
# Each state should be prepared to deal with it.
# Set $error to cause the program to immediately halt.
# $error is the return value of the program.
#-----------------------------------------------------------

my $done  = 0;
my $error = 0;

#-----------------------------------------------------------
# Define actions to take on state entry and exit.  
# Transitioning to the current state does not retrigger the 
# entry action.
# 
# If you wanted to number the bullets, this would be a good 
# place to reset a counter.  If you were building a data 
# structure, you might init on entry and store on exit.
# 
# In this case, I simply log state entry and ignore exit. 
#-----------------------------------------------------------

my @actions = ();

# log entry into each state for debugging
$actions[stStart]   = [sub{print LOG "Enter Start\n";}   ];
$actions[stItem]    = [sub{print LOG "Enter Item\n";}    ];
$actions[stSubItem] = [sub{print LOG "Enter SubItem\n";} ];
$actions[stEnd]     = [sub{print LOG "Enter End\n";}     ];

#-----------------------------------------------------------
# For each state, define a table of state transitions. Each 
# transition has a test with the action to take and the new 
# state to enter if the test succeeds. The actual order 
# expected is Next State, Test, Action. I make heavy use of 
# the implicit $_.
# 
# The order of tests is from first entry to last.  If the 
# test is undef, then that action is taken.  It is a 
# good idea to have an undef test as the last entry for 
# each state. 
#
# The input lines are chomped and cleaned of leading and
# trailing whitespace, so /^$/ is OK for finding blank 
# lines.
#-----------------------------------------------------------

my @states = ();

  # Next State, Test,        Action

$states[stStart] = [
    [stEnd,     sub{$done},  undef                       ],
    [stEnd,     sub{/^-\s/}, sub{error_start}            ],
    [stStart,   sub{/^$/},   undef                       ],
    [stItem,    undef,       sub{start_list; start_item} ],
];

$states[stItem] = [
    [stEnd,     sub{$done},  sub{end_item; end_list}     ],
    [stSubItem, sub{/^-\s/}, sub{start_sublist; 
                                 output_subitem}         ],
    [stStart,   sub{/^$/},   sub{end_item; end_list}     ],
    [stItem,    undef,       sub{end_item; start_item}   ],
];

$states[stSubItem] = [
    [stEnd,     sub{$done},  sub{end_sublist; end_list}  ],
    [stSubItem, sub{/^-\s/}, sub{output_subitem}         ],
    [stStart,   sub{/^$/},   sub{end_sublist; end_list}  ],
    [stItem,    undef,       sub{end_sublist; start_item}],
];

#-----------------------------------------------------------
# Initialize the machine
#-----------------------------------------------------------

my $fsm = new DFA::Simple \@actions, \@states;
$fsm->State(stStart);

#-----------------------------------------------------------
# Process the input
#-----------------------------------------------------------

while (<>) {
    chomp;

    # log input line for debugging
    print LOG "Input <$_>\n";

    # trim input and get rid of leading "o " bullet
    s/^\s+//;
    s/\s+$//;
    s/^o\s+//;

    # process this line of input
    $fsm->Check_For_NextState();

    # get out if an error occurred
    last if $error;
}

#-----------------------------------------------------------
# Set the done switch and allow one last transition,
# unless an error occurred.
#-----------------------------------------------------------

unless ($error) {
    # finish up
    $done = 1;
    $fsm->Check_For_NextState();
}

close LOG;
exit $error;

#-----------------------------------------------------------
# Action Subroutines
#-----------------------------------------------------------

sub start_list() {
    print "<ul>\n";
}

sub end_list() {
    print "</ul>\n";
}

sub error_start() {
    print "\nCannot start with subitem\n"; 
    $error = 1;
}

sub start_sublist() {
    print "\n    <ul>\n";
}

# ending a sublist also ends the enclosing item
sub end_sublist() {
    print "    </ul>\n";
    print "  </li>\n";
}

sub start_item() {
    chomp;
    print "  <li>$_";
}

sub end_item() {
    print "</li>\n";
}

sub output_subitem() {
    s/^-\s+//;
    print "      <li>$_</li>\n";
}

__END__

=head1 NAME

fix_bullets.pl - Convert MS Word bullets to HTML

=head1 SYNOPSIS

 fix_bullets.pl input_files > output_file

=head1 DESCRIPTION

This program filters stdin to stdout.
It creates HTML unordered lists from converted 
MS Word text.  

The expected input looks like this:

  o Major bullet point 1
    - Minor point
    - Another minor point
  o Major point 2

  o Blank line starts another group of points...
  o More of second group
    - More minor points
    - Yet another point

The output from the above:

  <ul>
    <li>Major bullet point 1
    <ul>
      <li>Minor point</li>
      <li>Another minor point</li>
    </ul>
    </li>
    <li>Major point 2</li>
  </ul>
  <ul>
    <li>Blank line starts another group of points...</li>
    <li>More of second group
    <ul>
      <li>More minor points</li>
      <li>Yet another point</li>
    </ul>
    </li>
  </ul>

Any line starting with whitespace, dash, whitespace is 
taken to be a minor bullet point. All other lines are 
assumed to be major points.  A leading "o" followed by 
whitespace is removed.

=head1 SEE ALSO

Finite State Machines Using DFA::Simple

=head1 COPYRIGHT

Copyright 2004 Bill Ruppert.

This program is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Bill Ruppert

=cut
