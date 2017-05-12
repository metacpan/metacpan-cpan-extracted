use strict;
use warnings;
use Auto::Mata;
use Types::Standard -types;

my $NoData   = Undef,
my $HasFirst = Tuple[Str];
my $HasLast  = Tuple[Str, Str];
my $Complete = Tuple[Str, Str, Int];

sub get_input {
  my $query = shift;
  print "\n$query ";
  my $input = <STDIN>;
  chomp $input;
  return $input;
}

my $fsm = machine {
  ready 'READY';
  term  'TERM';

  transition 'READY', to 'FIRST',
    on $NoData,
    with { return [get_input("What is your first name? ")] };

  transition 'FIRST', to 'LAST',
    on $HasFirst,
    with { return [@$_, get_input("What is your last name? ")] };

  transition 'LAST', to 'AGE',
    on $HasLast,
    with { return [@$_, get_input("What is your age? ")] };

  transition 'AGE', to 'TERM',
    on $Complete;
};

my $prog = $fsm->();
my $data = $prog->();

printf "Hello %s %s, aged %d years!\n", @$data;
