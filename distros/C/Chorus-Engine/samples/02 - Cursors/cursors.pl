#!/usr/bin/perl
#
use Chorus::Frame;
use Chorus::Expert;
use Chorus::Engine;

my $eng  = Chorus::Engine->new();
my $xprt = Chorus::Expert->new()->register($eng); # entry point ($xprt->process())

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

use constant STOCK_SIZE => 100;   # RESIZE YOUR TERMINAL TO HAVE AT LEAST 100 COLUMNS
use constant TARGET     => 0.5;   # mini ecart-type wanted

my $count = 0;

my $CURSOR = Chorus::Frame->new(
   increase => sub { $SELF->set('level', $SELF->level + 0.5); }, # dont use syntax $SELF->{level} with frames (see _VALUE)
   decrease => sub { $SELF->set('level', $SELF->level - 0.5); },
   increase_counter => sub { ++$count }
);

my $LEVEL = Chorus::Frame->new(
   _AFTER   => sub { $SELF->increase_counter } # Note -$SELF (~ the current context) is a CURSOR (not a LEVEL) !

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
             once => 'Y', # once a loop (always true)
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
             once => 1, # once a loop (always true)
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
