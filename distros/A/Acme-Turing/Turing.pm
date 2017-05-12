package Acme::Turing;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.02';

%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

#--- Create the Turing machine.
sub new {
 my $invocant = shift;
 my $class = ref($invocant) || $invocant;
 my $self = {
   steps => undef,
   spec => {},
   tape => [],
   tape_pos => 0,
   cur_state => 'START',
   @_ };

 $self->{'steps'} ||= 250;
 my $tapelen = 200;
 $self->{'tape'} = [ (" ") x $tapelen ];
 $self->{'tape_pos'} = int($tapelen / 2);

 return bless($self, $class);
}

# Add an entry to the spec hash.
sub add_spec {
 my $self = shift;
 my ($hkey, $hentry) = @_;
 Carp::croak("No entry defined") unless defined($hentry);

 $self->{'spec'}{$hkey} = $hentry;
 return;
}

# Initialize the tape.
sub init_tape {
 my $self = shift;
 my ($startpos, @symbols) = @_;
 my @Tape = @{$self->{'tape'}};
 Carp::croak("Start position $startpos is not on tape")
   if $startpos < 0 || $startpos > $#Tape;

 my $i;
 for ($i = 0; $i < @symbols ; $i++) {
   $self->{'tape'}[$startpos + $i] = $symbols[$i];
 }
 return;
}

# Step the machine to the next state.  The next state is returned.
sub step {
 my $self = shift;
# $ps = previous state.  $tp = tape position.  $ts = tape symbol.
 my $ps = $self->{'cur_state'};
 my $tp = $self->{'tape_pos'};
 my $ts = $self->{'tape'}[$tp];

# Find the instructions for this state and tape symbol.  If the tape
# symbol doesn't exist, try ANY; if that doesn't exist, fail.
 my $st_key = "$ps:$ts";
 if (! defined($self->{'spec'}{$st_key})) {
    $st_key = "$ps:ANY";
    die "Machine aborted: no action defined for state $ps/symbol $ts"
       unless defined($self->{'spec'}{$st_key});
 }
 my $actions = $self->{'spec'}{$st_key};
 my ($inst1, $next_state) = split /:/, $actions;

# Parse the instructions (P, L, R, E).
 $inst1 =~ s/\s//g;
 my @instruc = split /,/, $inst1;
 foreach (@instruc) {
    if (/^P/) {   # Write to the tape
       my $data = substr($_, 1);
       $self->{'tape'}[$tp] = $data  if $data ne "";
    } elsif (/^E/) {
       $self->{'tape'}[$tp] = ' ';
    } elsif (/^[LR]/) {
#--- Move the tape.  If we go beyond the end, make it bigger.
       my @Tape = @{$self->{'tape'}};
       $tp += (substr($_,0,1) eq 'L') ? -1 : 1;
       if ($tp < 0) {
          unshift(@Tape, (" ") x 50);
          $self->{'tape'} = [ @Tape ];
          $tp += 50;
       } elsif ($tp > @Tape - 1) {
          push(@Tape, (" ") x 50);
          $self->{'tape'} = [ @Tape ];
       } else { ; }
    } else {
       warn "Invalid instruction <$_> for state $ps";
    }
 }

 $self->{'tape_pos'} = $tp;
 $self->{'cur_state'} = $next_state;
 return $next_state;
}

# Print part of the current contents of the tape.  We print the 
# symbol at the current tape position, along with L symbols to
# the left and R to the right.
sub print_tape {
 my $self = shift;
 my ($L, $R) = @_;
 $L ||= 2; $R ||= 2;  # Defaults
 my $i;
 my $tp = $self->{'tape_pos'};

 for ($i = $tp - $L; $i <= $tp + $R; $i++) {
    print "    Tape [$i] ", ($i == $tp) ? ">>> " : "    ",
      "$self->{'tape'}[$i]\n";
 }
 return;
}

# Run the machine.
sub run {
 my $self = shift;
 my ($L, $R) = @_;
 $L ||= 2; $R ||= 2;

 my $current_state = 'START';
 my $step_num = 0;
 printf "%4d  %s\n", $step_num, $current_state;
 $self->print_tape(2,2);
 while ($current_state ne 'STOP') {
    print '-' x 60, "\n";
    $current_state = $self->step();
    $step_num++;
    printf "%4d  %s\n", $step_num, $current_state;
    $self->print_tape($L,$R);
    if ($step_num == $self->{'steps'}) {
       print "------> Reached maximum number of steps.\n";
       last;
    }
 }
 print "---> Machine stopped.\n";
 return;
}

1;

__END__

=head1 NAME

Acme::Turing - Turing machine emulation

=head1 SYNOPSIS

  use Acme::Turing;

  $machine = Acme::Turing->new(steps=>$steps);
  $machine->add_spec($conditions, $actions);
  $machine->init_tape($startpos, LIST...);
  $machine->step();
  $machine->print_tape($L, $R);
  $machine->run();

=head1 DESCRIPTION

This module gives you the methods needed to emulate a Turing machine
in Perl.

Why? Because we can.

This module is based on Turing's original paper (see REFERENCES),
which allows complete freedom in the actions to be taken
before the machine enters a new state. You can, of course,
impose restrictions if you wish, as John von Neumann's paper does.
This module allows the states to be designated by any alphanumeric
character string, and any non-blank alphanumeric data can be written
on the tape.

=head1 METHODS

The methods are listed below in the order you would be most likely
to call them in.

=over 2

=item B<new> steps=>STEPS

Creates the Turing machine.  The argument
is optional. It specifies a maximum number of steps that
the machine is allowed to go through before it is forced to stop
(to avoid endless looping); the default is 250 steps. The machine
will be created with a tape that is initially 200 squares in length.
Turing machine
tapes, however, are infinite, so the tape will be automatically made
longer whenever necessary; the only limit on the tape length is the
amount of available storage.

The newly created machine is in the START state.  The tape is
initialized to a series of single blanks (i.e., scalars
of length 1 containing ' ').  The tape head is positioned over the
middle of the tape, i.e. at C<int($tape_length/2)> = 100 =
the 101st symbol. Every square must contain
at least one character; empty strings are not allowed.
Also, blanks may not be written except by "erasing" (see below).

new() returns a hash reference.  The specification for the machine
(C<$machine-E<gt>{spec}>) is empty.
You must then populate the specification
for your machine, as described next.

=item B<add_spec> CONDITIONS ACTIONS

Adds an entry to the specification hash.
You can also add an entry by using this statement:

  $machine->{'spec'}{"my_conditions"} = "my_actions";

Both arguments must be specified.  The first must contain a state
and a tape symbol separated by a colon (:).  For example:

  'START: '            state START; tape contains a single blank
  'OUTOFCONTROL:junk'  state OUTOFCONTROL; tape contains 'junk'
  'COMATOSE:'          invalid; tape must contain a non-empty string

There is one reserved tape symbol: ANY (which really means "any
other").  For instance, if the machine is in the BEHIND state,
you can specify both 'BEHIND:time' and 'BEHIND:ANY'.  If the tape
contains 'time', the actions for 'BEHIND:time' will be executed; if
it contains anything else, 'BEHIND:ANY' will be used.

The second argument must contain two elements separated by colons
(:).  These specify
the actions to be taken by the machine
and the next state to be assumed by the machine (any alphanumeric
string).
The first field may contain any combination of these commands,
separated by commas:

  Px  print symbol <x> (character string without blanks) on the tape
  R   move the tape one square to the right
  L   move the tape one square to the left
  E   "erase" the current square on the tape (i.e., make it a blank)

The symbol to be printed cannot contain blanks.
If the first field is empty, the machine will do nothing. For example:

  'Phohum, R:NEXT'  Write 'hohum', move tape forward, enter state NEXT
  'PX, L:5'         Write 'X', move tape backward, enter state 5
  'L, P1:Q'         Move tape backward, write '1', enter state Q
  ':STOP'           Do not write, don't move the tape, go to STOP

There are two reserved states: START and STOP.  The machine always
begins in state START and stops when it enters state STOP.

=item B<init_tape> STARTPOS LIST

Writes symbols to the tape.  You may use this method to initialize
the tape before starting the machine.  STARTPOS is the position of
the tape to start writing in; there may be any number of symbols
after that.

=item B<step>

After the machine has been specified, this method will execute
one instruction (one state transition) on the machine.
It returns the resulting state of the machine, which is also stored
in C<$machine-E<gt>{cur_state}>.

=item B<run> L R

Runs the machine, beginning at state START.  After each step, the
current machine state and part of the tape will be printed.  The
machine will stop when it reaches the STOP state or when the maximum
number of steps has been executed. L and R are as defined for
print_tape().

=item B<print_tape> L R

Prints part of the current contents of the tape: the symbol under
the read/write head, L symbols to the left of it, and R symbols
to the right.  Both L and R default to 2.

=back

=head1 EXAMPLE

The following example computes the logical OR of two symbols.

  use Acme::Turing;
  $m1 = Acme::Turing->new();
  $m1->init_tape(100, '0', '1');
  $m1->add_spec('START:0', "R:MAYBE");
  $m1->add_spec('START:1', "R:IGNORE");
  $m1->add_spec('MAYBE:1', "R, Ptrue:STOP");
  $m1->add_spec('MAYBE:0', "R,Pfalse, R:STOP");
  $m1->add_spec('IGNORE:ANY', "R,Ptrue:STOP");
  $m1->run();

=head1 USEFULNESS

Well, uh, this module isn't really useful for much of anything.

=head1 REFERENCES

Alan M. Turing, "On Computable Numbers, with an Application to the
Entscheidungsproblem", I<Proceedings of the London Mathematical
Society>, 2nd series, 42 (1936-37), 230-265.

This paper is also reprinted in his I<Collected Works>,
specifically in I<Mathematical Logic>,
ed. R. O. Gandy and C. E. M. Yates
(Amsterdam: Elsevier Science, 2001).
At this writing, it is also available at
http://www.abelard.org/turpap2/tp2-ie.asp.

John von Neumann, "The General and Logical Theory of Automata", in
I<The World of Mathematics> (New York: Simon and Schuster, 1956),
vol. 4, p. 2093.

Von Neumann's description is more restrictive than Turing's.
To emulate the machine that von Neumann describes, you must restrict
your tape to two possible symbols ('0' and '1', for instance, or
' ' and 'X') and perform no more than one write and one tape movement
per step.  He also designates the machine states by numbers (0..n)
rather than by arbitrary character strings.

=head1 AUTHOR

Geoffrey Rommel (GROMMEL@cpan.org), January 2003.

=cut
