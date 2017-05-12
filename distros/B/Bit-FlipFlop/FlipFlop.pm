package Bit::FlipFlop;

use strict;
#use warnings; # no warnings pragma - we'll try to be 5.005 compatible
use Carp;
$Bit::FlipFlop::VERSION = '0.01';

# this will hold the flip flops' guts,
# keyed by stringified object references
%Bit::FlipFlop::stash = ();

########################################
# Public methods
#
# read the pod for usage
# 
# the rest of this is an obsfucated black box.  just kidding.

sub new {
  my $class = shift;
  my %args = @_;

  my $ff=0;
  my $f=bless \$ff, $class;

  $f->_init(%args);
  return $f;  
}

sub test {
  my $f = shift;

  $Bit::FlipFlop::stash{"$f"}{ff} ||= $f->_build_ff;

  $$f = &{$Bit::FlipFlop::stash{"$f"}{ff}};
}

*Bit::FlipFlop::clock=\&test;

sub state {
  ${$_[0]}?1:0;
}

sub series {
 +${$_[0]};
}

sub lead_edge {
 ${$_[0]}==1?1:0;
}

sub trail_edge {
 ${$_[0]}=~/E/?1:0;
}

sub next_test {
 !${$_[0]}||$_[0]->trail_edge?'set':'reset';
}


########################################
# Private methods

sub _init {
  my $f = shift;
  my %args = @_;

  croak '"set" and "reset" coderef attributes are required.'   
    unless defined($args{set}) and ref($args{set}) eq 'CODE' 
       and defined($args{reset}) and ref($args{reset}) eq 'CODE';

  $args{simultaneous_edges} = 1 
    unless defined $args{simultaneous_edges};

  @{$Bit::FlipFlop::stash{$f}}{qw/set reset dotdot/} = 
    @args{qw/set reset simultaneous_edges/};
}

sub _build_ff {
  my $f = shift;

  my $op = $Bit::FlipFlop::stash{$f}{dotdot}?'..':'...';

  my $s = qq[
    sub { 
     &{\$Bit::FlipFlop::stash{"$f"}{set}} 
       $op 
     &{\$Bit::FlipFlop::stash{"$f"}{reset}}
    }
  ];

# debug:
#  print $s;
  eval $s;
}
1;
__END__

=head1 NAME

Bit::FlipFlop - Facilitates the maintainance of one bit of state in Perl
programs.  

=head1 SYNOPSIS

  use Bit::FlipFlop;

  my $f = Bit::FlipFlop->new(set   => sub { /start/ },
                             reset => sub { /end/ });

  for (<INPUT>) {
    $f->test;

    print "**leading edge**\n" if $f->lead_edge;
    print "number ", $f->series, ":  $_" if $f->state;
    print "**trailing edge**\n" if $f->trail_edge;
  }

  # -- or --

  #use Bit::FlipFlop

  my $f;
  for (<INPUT>) {
    $f = /start/ .. /end/;  
    
    print "**lead edge**\n" if $f == 1;
    print "number ", +$f, ":  $_" if $f;
    print "**trailing edge**\n" if $f =~ /E/;
  }
   

=head1 DESCRIPTION

Maintaining one bit of state in a program can be a very useful thing. A
Bit::FlipFlop does just that. The flip flop can be false (represented
by the integer 0) or true (1).

=head2 Overview

The initial state of a flip flop is false.  It has an opportunity
to change state during each call to the C<test> method.  

Two callbacks are provided at flip flop construction time, C<set> and
C<reset>. One or both of these callbacks may be evaluated when the
C<test> method is called. The callbacks are evaluated in scalar context,
and their return value is interpreted as a boolean.

While false, the flip flop evaluates the C<set> callback at each call to
the C<test> method. If the C<set> callback returns a true value, the
flip flop flips state to true. While true, the flip flop evaluates the
C<reset> callback when C<test> is called. If C<reset> returns a true
value, then the flip flop flops back into the false state. 

=head2 Edge Conditions and More

The Bit::FlipFlop actually maintains a few bits more state than just one.

When the flip flop changes from false to true, that is called the leading
edge.  Conversely, when its state falls from true to falls, that is known
as the trailing edge.  Bit::FlipFlop provides methods to test for these
"sub states", C<lead_edge> and C<trail_edge>.

Edges are easily seen when the state of a flip flop is plotted over time:

   true        +-------+        +---+      
               |       |        |   |     
   false  -----+       +--------+   +------
               ^       ^ 
   leading edge         trailing edge
               
Which condition will be tested next?

The C<next_test> method is provided to query the flip flop to see which
condition (C<set> or C<reset>) will be queried on the next call to the
C<test> method.

=head2 Bit::FlipFlop methods

The Bit::FlipFlop class provides an object oriented interface to the
flip flop.  

=over 4

=item C<new>

  $f = Bit::FlipFlop->new(set   => sub {$. == 15},
                          reset => sub {$. == 20},
                          simultaneous_edges => 0);

The C<new> method creates a new Bit::FlipFlop object.  A newly created 
flip flop's state is always false.  

The C<set> and C<reset> arguments are required. They are sub refs that
are used for callbacks to test for setting or resetting the flip flop.

C<simultaneous_edges> is an optional argument that defaults to 1
(true) if unspecified. This argument governs whether the flip flop
may look for a leading edge and trailing edge within a single call to
the C<test> method.  

Normally when a flip flop is in the false state, it tests for the
C<set> condition. Should that condition be true, then the flip flop
will change states to true. There are two possible behaviors at this
point. The flip flop could either evaluate the C<reset> condition to
see if it should switch back to the false state *within the same call
to C<test>*, or it could postpone looking at the C<reset> condition
until the next call to C<test>.

The former behaviour is specified by C<simultaneous_edges=E<gt>1>, 
which is the default behaviour if left unspecified.  To obtain a 
flip flop that will *not* check for both edge conditions within
a single call to C<test>, specify C<simultaneous_edges=E<gt>0>.

=item C<test>

  $f->test;

The C<test> method evaluates one or both conditional tests (according to
the flip flop's state) and determines if the flip flop's state should be
inverted. An alias, C<clock> is provided for circuitry heads.

=item C<state>

  print "It's ", $f->state ? 'true' : 'false', ".\n";

To query the current state of a flip flop, call its C<state> method, which
will return a boolean value (1 for true, 0 for false).

For those just desperate to obsfucate some code, even while using a 
nice, clean OO interface, the boolean state of a flip flop is
also available as C<$$f>.  Don't do this.  In fact, just forget that
you read it.

  # don't you wish that you didn't fire me now?
  # muahahahaha ack plbbf..
  print "It's ", $$f? 'true' : 'false', ".\n";


=item C<series>

The C<series> method returns an integer that tells how many times
the C<test> method has been called since its state has been true.

C<series> will return 1 after the first call to C<test> has flip a
flip flop's state to true, and its return value will be incremented
by one each time that C<test> is called and the state remains true.

A call to C<series> while the flip flop is false will return 0.

=item C<lead_edge>

  print "Just passed the leading edge of truth.\n" 
    if $f->lead_edge;

The C<lead_edge> method returns true if the last call to C<test> caused
the flip flop to change state from false to true.

=item C<trail_edge>

  print "About passed from truth to despair.\n"
    if $f->trail_edge;

The trailing edge, when a flip flop is about to change state from
true to false, can be detected by calling the C<trail_edge> method.

It is useful to note that when passing the trailing edge, the *reported*
state is true, while the internal state is false. That is, during the
*next* call to C<test>, the flip flop will check the C<set> conditional
to see if it should switch to true.

  # to print out content between the set event and
  # reset event, excluding the edges themselves, 
  # one might:

  use Bit::FlipFlop;

  my $f = Bit::FlipFlop->new(set   => sub { /start/ },
                             reset => sub { /end/ });

  for (<INPUT>) {
    $f->test;

    if ($f->state and not($f->lead_edge or $f->trail_edge)) {
      print;
    }
  }


=item C<next_test>

The C<next_test> method lets one query the flip flop to see which 
callback will be tested on the next call to C<test>.  It will return
a string, either 'set' or 'reset'.  

* Note that in the default case, a flip flop tests the output of both
call backs during the call to C<test> that represents a leading 
edge.

=back

=head2 Super Stealth Built in Operator Mode

The functionallity that Bit::FlipFlop provides is so useful, that it can
be accessed just like a built in Perl operator. This is referred to as
"Super Stealth Built in Operator Mode", or B<SSBOM>. B<SSBOM> is the
preferred interface, and the author recommends only using the OO
interface as "training wheels".

One signals to the Bit::FlipFlop module that the B<SSBOM> interface is 
desired by commenting out the C<use> statement:

  #use Bit::FlipFlop;

B<Advantage of SSBOM>

Why should you go through the trouble of learning this slightly cryptic
B<SSBOM> interface? Well, for one reason is that the Bit::FlipFlop
module *need not be installed* on the target system. This alone is a
huge advantage. Another reason is that the B<SSBOM> interface has been
standard for many years, and is well known by *thousands* of Perl
programmers world wide. B<SSBOM> is more readily available, more well
known and thus lends to maintainable code.

Of course, since Bit::FlipFlop objects and their methods won't be
available, coding style must be adjusted. What follows are code excerpts
to accomplish the same things that the OO method calls do.  

=over 4

=item new

Instead of creating a Bit::FlipFlop object, use the C<..> or
C<...> operator.

  $result = set_condition() .. reset_condition();

Instead of subrefs, any Perl expression can be places on either side of
the operator. The expression on the left side is taken as the set
condition, that on the right as the reset condition.

If a flip flop with the attribute of C<simultaneous_edges=E<gt>1> is
desired, then use the C<..> operator.  C<...> has the functionallity
of C<simultaneous_edges=E<gt>0>.  

=item test

Under the B<SSBOM> interface, the flip flop tests its conditionals to see
if it needs to change state each time it is evaluated.

=item state

When a flip flop is evaluated, it return value, taken in a boolean
sense, represents the state of the flip flop. Should one wish to test
the state some time after the flip flop has been evaluated, then save
the return value into a scalar variable.

This OO example: 

  my $f = Bit::FlipFlop->new(set => sub { $_ == 3 },
                             reset => sub { $_ == 7 });
  for (1..10) {
    $f->test;
    if ($f->state) {
      ++$count;
    } 
  }

Under B<SSBOM> becomes:

  for (1..10) {
    if ($_ == 3 .. $_ == 7) {
      ++$count;
    }
  }    

You may have noticed the dual use of the C<..> operator in that example.
This is an illusion. The characters C<..>, when evaluated in list
context is the normal range operator that you are used to.
Bit::FlipFlop's B<SSBOM> interface only applies to C<..> or C<...> in
scalar context.

=item series

To determine how many times a flip flop has been evaluated since being
in the true state, numerify its return value. This number includes the
evaluation that caused the flip flop to flip states to true. If the flip
flop is in the false state, then using this "method" will yield the
integer zero (0).

  $r = set_test() ... reset_test();
  # this same $r is present in the examples below

  print 'the flip flop has been true for ', +$r, " iterations.\n";

=item lead_edge

The leading edge, when a flip flop changes from the false state to true
can be detected by testing the series for number 1.

  print "leading edge\n" if $r == 1;

=item trail_edge

The trailing edge is when the flip flop changes from a state of true to
false.  This is indicated in the B<SSBOM> interface by appending the string
'E0' to the return value of a flip flop's evaluation.  Note that 
when the return value is interpreted numerically or as a boolean, that 
the presence or lacking of the 'E0' appendix is irrelevant.  

  print "trailing edge\n" if $r =~ /E/;

=item next_test

A flip flop will test the C<set> condition (left hand expression) when
the trailing edge has been crossed, or when its state is false.

  print "will check left term next" if (not $r) or $r =~ /E/;

On the other hand, the flip flop will check the right hand expression
(the C<reset> conditional) if the state is true, and the trailing edge
has not yet been crossed.

  print "will check right term next" if $r and $r !~ /E/;

=back

=head1 BACKGROUND

=head2 Digital Logic

Perl's flip flop operator has roots in digital logic circuitry.  

           ___                     $a  $b  | $o   
  $a -----|   \                   ---------|----       
          |    |o---- $o            F   F  |  T        
  $b -----|___/                     T   F  |  T        
                                    F   T  |  T        
                                    T   T  |  F    

The NAND gate.  Its logical function could be expressed in Perl 
as C<$o = not($a and $b);>.  One diffence in the function of the NAND
gate and its Perl equivalent is that the NAND gate's output ceases
to retain its logical state when the input has been removed.  It sure
would be nice to be able to maintain that bit of state.


   _       ___                          _   _   _
  $s -----|   \                    $q  $q  $s  $r  |  $q
          |    |o-+-- $q          -----------------+-----
        +-|___/   |                 F   T   T   T  |   F
        |        /                  F   T   F   T  |   T  
        |      /                    T   F   T   T  |   T
        \__  /___                   T   F   T   F  |   F   
           /     \                                 |
         /        |               . . .            |
        |  ___    |                                |
        +-|   \   |    _            T   F   F   F  |  ?!?
   _      |    |o-+   $q 
  $r -----|___/         

The RS Latch uses two NAND gates to maintain one bit of logical state
after the input has been removed. (The output of the top NAND gate is
connected to one of the inputs of the lower gate and vice versa, if my
ASCII art isn't quite clear.) Its function is along the lines of this
Perl: C<$q = !$s ... !$r;>. One difference between the functionallity of
the RS Latch and the provided Perl equivalent is that the latch's output
is undefined if $s and $r should be logical false at the same time.

This idea is further developed in digital circuitry in the RS Flip Flop
and the JK Flip Flop. The code C<$q = !$s ... !$r;> is very close to the
action of the JK Flip Flop, if one abstracts the JK's notion of the
Clock input being True as equivalent to the moment of execution of the
C<...> operator.

The curious reader can find lots of information about digital logic by
googling on some of these keywords.

=head2 ed, etc

Perl's concept of the flip flop op was inherited from B<awk>, who got
it from B<sed>, which got it from B<ed> and so on.

The B<ed> command (prepend it with a colon, and it's a B<vi> command),
C</start/,/stop/s/flip/flop/> can be seen in Perl as 
C<perl -pi -e's/flip/flop/ if /start/.../stop/'>.  

=head1 HISTORY 

=over 8

=item 0.01

Original version; 

=back


=head1 AUTHOR

Colin Meyer, E<lt>cmeyer@helvella.orgE<gt>

=head1 SEE ALSO

L<perl>.
L<perlop>.

=cut
