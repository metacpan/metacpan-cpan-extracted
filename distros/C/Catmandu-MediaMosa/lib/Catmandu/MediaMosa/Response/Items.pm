package Catmandu::MediaMosa::Response::Items;
use Catmandu::Sane;
use Moo;
use Data::Util qw(:check :validate);

has items => (
  is => 'ro',isa => sub{
    my $items = $_[0];
    array_ref($items);
    for(@$items){
      hash_ref($_);
    }        
  }
);

sub generator {
  my $self = shift;
  my $sub = sub {
    state $i = 0;
    if($i < scalar(@{ $self->items })){
      return $self->items->[$i++];
    }else{
      return undef;
    }
  };
  return $sub;   
}

with('Catmandu::Iterable');

1;
