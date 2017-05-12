use strict;
use warnings;
use List::Util qw(reduce);
use Types::Standard -all;
use Type::Utils -all;
use Auto::Mata;

my %OP = (
  '+'  => sub { $_[0]  + $_[1] },
  '-'  => sub { $_[0]  - $_[1] },
  '*'  => sub { $_[0]  * $_[1] },
  '/'  => sub { $_[0]  / $_[1] },
  '**' => sub { $_[0] ** $_[1] },
);

sub welcome { print "\nWelcome to the example calculator!\n\n" }
sub goodbye { print "\nThanks for playing! Goodbye!\n\n" }

sub error {
  my $invalid = shift;
  if (exists $OP{$invalid}) {
    print "At least two terms are required before an operator may be applied.\n\n";
  } else {
    print "I do not understand '$invalid'. Please enter a term or operator.\n\n";
  }
}

sub input {
  my @terms = reverse @_;
  print "terms> @terms\n" if @terms;
  print "input> ";

  my $value = <STDIN>;
  print "\n";

  ($value) = $value =~ /\s*(.*)\s*$/;
  reverse split /\s+/, $value;

  return $value, @_;
}

sub solve {
  my ($op, @terms) = @_;
  @terms = reverse @terms;
  my $n  = reduce { $OP{$op}->($a, $b) } @terms;
  my $eq = join " $op ", @terms;
  print "  $eq = $n\n\n";
}

my @exit  = qw(quit q exit x);
my @clear = qw(clear cl c);

my $Term       = declare 'Term',       as Num;
my $Op         = declare 'Op',         as Enum[keys %OP];
my $Exit       = declare 'Exit',       as Enum[@exit];
my $Clear      = declare 'Clear',      as Enum[@clear];
my $Cmd        = declare 'Cmd',        as Enum[@exit, @clear];
my $Input      = declare 'Input',      as $Term | $Op | $Cmd;
my $Incomplete = declare 'Incomplete', as ArrayRef[$Term];
my $Equation   = declare 'Equation',   as Tuple[$Op, $Term, $Term, slurpy ArrayRef[$Term]];
my $Command    = declare 'Command',    as Tuple[$Cmd,   slurpy ArrayRef[$Term]];
my $ExitCmd    = declare 'ExitCmd',    as Tuple[$Exit,  slurpy ArrayRef[$Term]];
my $ClearCmd   = declare 'ClearCmd',   as Tuple[$Clear, slurpy ArrayRef[$Term]];
my $Invalid    = declare 'Invalid',    as ~$Incomplete & ~$Equation & ~$Command;

my $builder = machine {
  ready 'READY';
  term  'TERM';
  transition 'READY',  to 'START',  on Undef,       with { welcome; [] };
  transition 'START',  to 'INPUT',  on $Incomplete;
  transition 'INPUT',  to 'INPUT',  on $Incomplete, with { [input(@$_)] };
  transition 'INPUT',  to 'ANSWER', on $Equation,   with { solve(@$_); [] };
  transition 'INPUT',  to 'ERROR',  on $Invalid,    with { error($_->[0]); $_ };
  transition 'ERROR',  to 'INPUT',  on $Invalid,    with { my ($bad, @stack) = @$_; \@stack };
  transition 'INPUT',  to 'START',  on $ClearCmd,   with { [] };
  transition 'INPUT',  to 'TERM',   on $ExitCmd,    with { goodbye; [] };
  transition 'ANSWER', to 'INPUT',  on $Incomplete;
};

my $fsm = $builder->();
$fsm->();
