package Chorus::Sample::Cursors;

use 5.006;
use strict;

our $VERSION = '1.03';

=head1 NAME

Chorus::Sample::Cursors - A example illustrating Chorus::Expert mecanism

=head1 VERSION

Version 1.03

=head1
 
  Here is an example trying to illustrate how Chorus::Engine works.
  Rules are just perl functions called in an infinite loop until one of them declares its agent solved.
  Each rule is tested with a combinaison of scope(s) of one or more parameters.

  The knowledge of the system is modelized with Chorus::Frame objects. This is not necessary
  since a rule can combinate any array given in its parameter _SCOPE but, the usage of the function fmatch(),
  combinated with grep, can be an efficient way to reduce and optimize the scopes of rules parameters by
  looking for elements of knowledge having certain properties.
  In the same time, any invocation of the frame methods get() & set(), can take advantage of the presence 
  of the slot _NEEDED or _AFTER, to respectively try to realize conditions (backward chaining) before providing 
  an information on a frame or/and propagate (~ forward chaining) a modification to the system - See Chorus::Frame documentation. 

  In this example, the system is composed of 100 cursors (frames), each one having a slot 'level' 
  with a random value (from 1 to 10).
  The goal is to move the system until the average distance of 'level' to the medium value 5 
  is lower than 0.5.
  
  Rule 1 : display the state of the system
  Rule 2 : check if the target is reached (will declare the system as solved)
  Rule 3 : decrease levels if > 5
  Rule 4 : increase levels if < 5
  
  Of course, such a system doesn't need an expert system to be solved but it can illustrate how Chorus::Expert works. 
  
  Note - try 'man Chorus::Sample::Cursors' if the following code doesn't appear correctly in your browser 

=cut

=head1

use Chorus::Expert;

use Chorus::Engine;

my $eng  = Chorus::Engine->new();

my $xprt = Chorus::Expert->new()->register($eng);

my @stock = ();

# --

use Term::ReadKey;

sub pressKey {
  while (not defined (ReadKey(-1))) {}

}

sub displayState {
   foreach my $l (0 .. 10) {
      	  my $lineChar = $l == 5 ? '-' : ' ';
      	  print (int($_->level + 0.5) == $l ? '+' : $lineChar) for (@stock);
         print "\n";
      	}
    print "\n\n";
    select(undef, undef, undef, 0.02); # pause for display

}

# -- MODELIZING SYSTEM WITH FRAMES

use Chorus::Frame;

use constant STOCK_SIZE => 100;   # RESIZE YOUR TERMINAL TO HAVE AT LEAST 100 COLUMNS

use constant TARGET     => 0.5;   # mini ecart-type wanted

my $count = 0;

my $CURSOR = Chorus::Frame->new(
   increase => sub { $SELF->set('level', $SELF->level + 0.5); }, # dont use syntax $SELF->{level} with frames (see _VALUE)
   decrease => sub { $SELF->set('level', $SELF->level - 0.5); },
   increase_counter => sub { ++$count }
);

my $LEVEL = Chorus::Frame->new(
   _AFTER   => sub { $SELF->increase_counter } # Note - $SELF (~ the current context) is a CURSOR not a LEVEL !

);

push @stock, Chorus::Frame->new(
 _ISA     => $CURSOR,
 level    => {
 	            _ISA   => $LEVEL,
 	            _VALUE => int(rand(10) + 0.5)
             }

) for (1 .. STOCK_SIZE); # populating

# --

$eng->addrule( # RULE 1
      _SCOPE => {
             once => [1],
      },
      _APPLY => \&displayState
);

# --

sub checksolved {
  my ($average, $ecart) = (0,0);
  $average += $_->level for(@stock);
  $average /= STOCK_SIZE;
  $ecart += abs($_->level - $average) for(@stock); # @stock equiv. to fmatch(slots=>'level') here
  $ecart /= STOCK_SIZE;
  return ($ecart < TARGET);

}

$eng->addrule( # RULE 2

      _SCOPE => {
             once => [1], # once a loop too
      },
      
      _APPLY => sub {
        return $eng->solved if checksolved(); # delared the whole system as solved (will exit from current $xprt->process())
        return undef;                         # rule didn't apply
      }
      
);

# --

$eng->addrule( # RULE 3
      _SCOPE => { frame => sub { [ grep { $_->level < 5 } fmatch(slot=>'level') ] } }, # frames with level < 5
      _APPLY => sub {
         my %opt = @_;
      	  $opt{frame}->increase;
      }
      
);

# --

$eng->addrule( # RULE 4
      _SCOPE => { frame => sub { [ grep { $_->level > 5 } fmatch(slot=>'level') ] } }, # frames with level > 5
      _APPLY => sub {
      	 my %opt = @_;
      	 $opt{frame}->decrease;
      }
      
);

# --

displayState();

print "Press a key to start"; pressKey();

$xprt->process();

print "Total : $count updates\n";

=cut

1;
