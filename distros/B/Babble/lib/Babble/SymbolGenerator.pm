package Babble::SymbolGenerator;

use Mu;

ro count => (default => '001');

sub gensym {
  my ($self) = @_;
  my $sym = '__B_'.$self->{count}++;
  return $sym;
}

1;
