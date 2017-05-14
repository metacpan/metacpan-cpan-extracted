#================================= FSM.pm ====================================
# Filename:             FSM.pm
# Description:          A simple Finite State Machine.
# Original Author:      Dale M. Amon
# Revised by:           $Author: amon $ 
# Date:                 $Date: 2008-08-28 23:14:03 $ 
# Version:              $Revision: 1.7 $
# License:		LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Fault::DebugPrinter;
use Fault::ErrorHandler;

package DMA::FSM;

#=============================================================================
#			Exported Routines
#=============================================================================

sub FSM {
  my ($fst, $blackboard, @lexlst) = @_;
  my ($next,$lexaction,$lexeme,$printlex) = (undef,undef,undef,"");
  my ($state,$mode) = ("S0","RUN");
  my $branch;

  # No one gets out of this loop without the state tables permission!
  while (1) {
    $lexeme = shift @lexlst;
    $printlex = (defined $lexeme) ? $lexeme : "";
    Fault::DebugPrinter->dbg (3, "\nCurstate $state: <$printlex>");

  LEXANAL: while ($_=$mode) {

      # We should never see an undefined state unless we've made a mistake.
      if (! exists $fst->{$state} ) {
	Fault::ErrorHandler->die ("FATAL: Impossible state during parse!");
      }

      if (/RUN/)
	{
	  if (!defined $lexeme)
	    { ($state,$lexaction) = @{$fst->{$state}}[0..1];
	      Fault::DebugPrinter->dbg
		  (4," Nextstate $state: End of Lexemes");
	    }
	  else {
	    ($branch, $lexeme) = 
		(&{$fst->{$state}[2]} ($lexeme, $blackboard ));
	    $printlex = (defined $lexeme) ? $lexeme : "";
	    if ($branch) {
	      ($state,$lexaction) = @{$fst->{$state}}[3..4];
	      Fault::DebugPrinter->dbg
		  (4,
		   " Nextstate $state: Left  branch with lexeme <$printlex>");
	    }
	    else
	      { ($state,$lexaction) = @{$fst->{$state}}[5..6];
		Fault::DebugPrinter->dbg
		    (4,
		     " Nextstate $state,$lexaction: Right branch with <$printlex>");
	      }
	  }
	  Fault::DebugPrinter->dbg (4, " Lexeme action: $lexaction");
	  if ($lexaction eq "TSTL") {if ($lexeme)   {next LEXANAL;}
				     else           {last LEXANAL;}}
	  if ($lexaction eq "SAME")                 {next LEXANAL;}
	  if ($lexaction eq "NEXT")                 {last LEXANAL;}
	  if ($lexaction eq "FAIL") {$mode = "ERR";  next LEXANAL;} 
	  if ($lexaction eq "DONE") {$mode = "DONE"; next LEXANAL;} 
	  Fault::DebugPrinter->dbg
	   (4," NextState $state: No such Action $lexaction");
	  $lexaction = "FAIL"; next LEXANAL;
	}

      # DONE: Parse succeeded!
      if (/DONE/)
	{ &{$fst->{$state}[2]} ((defined $lexeme) ? $lexeme : "",
				$blackboard );
	  Fault::DebugPrinter->dbg (4," DoneState $state: Exiting");
	  $blackboard->{'state'} = $state;
	  return (@lexlst);
	}
      
      # ERR: The string is not a valid Publication Filename Spec
      if (/ERR/)
	{ &{$fst->{$state}[2]} ((defined $lexeme) ? $lexeme : "",
				$blackboard );
	  Fault::DebugPrinter->dbg (4," ErrorState $state: Failing");
	  $blackboard->{'state'} = $state;
	  return (@lexlst);
	}
    }
  }
  Fault::DebugPrinter->dbg
      (4," Nextstate $state: Impossible! How did we escape the while loop???");
  return (@lexlst);
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documentation section with the 'perldoc' cmd.

=head1 NAME

 DMA::FSM - A simple Finite State Machine.

=head1 SYNOPSIS

 use DMA::FSM;
 my $fst       = { see text for format };
 my (@lexlst)  = ("First", "Second", "Third");
 my $bb        = {};
 my @remaining = DMA::FSM::FSM ( $fst, $bb, @lexlst);

=head1 Inheritance

 None.

=head1 Description

There is a single subroutine named FSM in this module. It will run a FSM 
machine of your choosing. It must contain, and will be started, in state 'S0'.
When called, lexical analyzer functions from the state  table will be passed
a user supplied 'blackboard' hash on which they may read, write and share 
results. The arguments to FSM are:

 1.Finite State Table
 2.ptr to a user blackboard hash
 3.a list of lexemes to be analyzed

It returns a list of unused lexemes, if any. If called from within an object,
it may be useful to use the self pointer for your  blackboard; your lexical
functions will then be able to execute instance methods as well as access
ivars (instance variables).

The machine is controlled by a state table and it is pretty basic:

 my $fst = 
 {'S0' => ["E0","SAME", \&_getFirstDate,  "S1","TSTL","S2","SAME"],
  'S1' => ["E1","SAME", \&_getSecondDate, "S2","TSTL","S2","SAME"],
  'S2' => ["E2","SAME", \&_getFirstBody,  "S3","NEXT","S3","NEXT"],
  'S3' => ["D0","SAME", \&_getBody,       "S3","NEXT","S3","NEXT"],
  'D0' => ["D0","DONE", \&_noop,          "","","",""],
  'E0' => ["E0","FAIL", \&_nullFileName,  "","","",""],
  'D1' => ["D1","DONE", \&_endsAt1stDate, "","","",""],
  'D2' => ["D2","DONE", \&_noBody,        "","","",""],
 };  

State table records are divided into four parts:

 * What to do if we don't have any more lexemes (a duple).
 * A lexical analyzer to be called if we do have a lexeme.
 * What to do if the function returns true (a duple).
 * What to do if the function returns false (a duple).

The first of the three pairs (0,1) are applied if the state is entered and
there are no more lexemes; the second pair (3,4) are applied if the specified
lexical analyzer routine (2) returns true; the third pair (5,6) if it returns
false.

The first item of each pair is the next state and the second is the action
part, a keyword SAME or NEXT to indicate whether to stay with the same  
lexeme (SAME) or to try to get the next one (NEXT) before executing the next 
state. TSTL means do a NEXT if the current $lexeme is empty, otherwise keep 
using it like SAME. Additional keywords DONE and FAIL are termination 
indicators. Both will stay keep the current lexeme.

Internally the state machine is also modal; it starts in 'RUN' state. When a 
new state has an action part of DONE, the mode is changed to 'DONE'. The next 
function to be executed will be in the DONE mode; the state machine will then 
terminate and return any unused lexemes. Similarly, if the action part is 
'FAIL', the mode becomes 'ERR' and the function of the new state is executed 
in that context, followed by an exit with the list of remaining lexemes.

It is up to the user to record any special failure information on their 
blackboard hash.

Unreachable states may be null; for instance if a lexical routine always 
absorbs the lexeme it is given, then it may chose to always return true or 
always return false. Thus  the other table duple is unreachable. Likewise, 
an error or done state does no further branching so both the left branch 
(true) and right branch (false) duple are unreachable.

A lexical analyzer routine is passed two arguments: the current lexeme and 
a user supplied blackboard hash as noted earlier. The  routine may do any 
tests it wishes and it may read and write anything it wants from the 
blackboard. It returns a list of two values, the firs of which must be true 
or false to differentiate between the two possible next states, a left branch
or a right branch. 

The second user return value is either undef or an unused  portion of the 
input lexeme. Thus a lexeme might be  passed to another (or the same) finite
state machine.

For example:

 sub _GetSecondaryTitle {
  my ($lexeme, $bb) = @_;
  if ($lexeme =~ /^[^A-Z]/) {
    # Left branch, lexeme is still virgin and reusable.
    return (1, $lexeme);
  } 

  $bb->{'secondary_title'} .= $bb->{'del'} . "$lexeme";
  $bb->{'del'} = "-";
  # Right branch, lexeme all used up.
  return (0,undef);
 }

This may mean extra states in your states diagram to limit states to a binary
choice of next state. But that shouldn't be too difficult.

=head1 Examples
 
 use DMA::FSM;
 my $fst       = { see text for format };
 my (@lexlst)  = ("First", "Second", "Third");
 my $bb        = {};
 my @remaining = DMA::FSM::FSM ( $fst, $bb, @lexlst);

=head1 Routines

=over4

=item B<@remaining = DMA::FSM::FSM ( $fst, $bb, @lexlst)>

Run a FSM machine of your choosing. Arguments are a Finite State Table, 
a ptr to blackboard hash and a list of lexemes to be processed by the FSM.

It returns a list of unused lexemes, if any.

=back4

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

Fault::DebugPrinter, Fault::ErrorHandler

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: FSM.pm,v $
# Revision 1.7  2008-08-28 23:14:03  amon
# perldoc section regularization.
#
# Revision 1.6  2008-08-15 21:47:52  amon
# Misc documentation and format changes.
#
# Revision 1.5  2008-04-11 22:25:23  amon
# Add blank line after cut.
#
# Revision 1.4  2008-04-11 18:56:35  amon
# Fixed quoting problem with formfeeds.
#
# Revision 1.3  2008-04-11 18:39:15  amon
# Implimented new standard for headers and trailers.
#
# Revision 1.2  2008-04-10 15:01:08  amon
# Added license to headers, removed claim that the documentation section still
# relates to the old doc file.
#
# Revision 1.1.1.1  2004-08-30 23:26:07  amon
# Dale's library of primitives in Perl
#
# 20040821      Dale Amon <amon@vnl.com>
#               Created. Finally, after talking about it for 
#		several years.
#
1;

