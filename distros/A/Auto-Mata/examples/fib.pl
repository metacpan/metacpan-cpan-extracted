#-------------------------------------------------------------------------------
# Calculates fibonacci numbers for arguments passed into the command line
#
# The algorithm used is based on the solution described here:
#   http://stackoverflow.com/a/16389221
#-------------------------------------------------------------------------------
use strict;
use warnings;
use Scalar::Util 'looks_like_number';
use Types::Standard -all;
use Type::Utils -all;
use Auto::Mata;

my $Number   = declare 'Number', as Str, where { looks_like_number $_ };
my $ZeroPlus = declare 'ZeroPlus', as $Number, where { $_ >= 0 };
my $Invalid  = declare 'Invalid', as ~$ZeroPlus;
my $Zero     = declare 'Zero', as $Number, where { $_ == 0 };
my $One      = declare 'One',  as $Number, where { $_ == 1 };
my $Term     = declare 'Term', as $Number, where { $_ >= 2 };
my $Start    = declare 'Start', as Tuple[$ZeroPlus];
my $Step     = declare 'Step', as Tuple[$Term, $ZeroPlus, $ZeroPlus];
my $CarZero  = declare 'CarZero', as Tuple[$Zero, $ZeroPlus, $ZeroPlus];
my $CarOne   = declare 'CarOne', as Tuple[$One, $ZeroPlus, $ZeroPlus];

my $FSM = machine {
  ready 'READY';
  term  'TERM';

  transition 'READY', to 'TERM', on $Invalid,  with { die 'invalid argument; expected an integer >= 0' };
  transition 'READY', to 'STEP', on $ZeroPlus, with { [$_, 1, 0] };
  transition 'STEP',  to 'STEP', on $Step,     with { [$_->[0] - 1, $_->[1] + $_->[2], $_->[1]] };
  transition 'STEP',  to 'TERM', on $CarZero,  with { $_->[2] };
  transition 'STEP',  to 'TERM', on $CarOne,   with { $_->[1] };
  transition 'STEP',  to 'TERM', on $ZeroPlus;
};

sub fib {
  my $term   = shift;
  my $acc    = $term;
  my $fibber = $FSM->();

  while (my @state = $fibber->($acc)) {
    ;
  }

  return $acc;
}

local $| = 1;

my $fibber = $FSM->();

foreach my $term (@ARGV) {
  print "fib($term) = ";
  print $fibber->($term), "\n";
}
