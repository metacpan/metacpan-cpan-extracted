package Data::Maker::Record;
use Moose;
use vars qw( $AUTOLOAD );

our $VERSION = '0.14';

has delimiter => ( is => 'rw' );
has fields => ( is => 'rw', isa => 'ArrayRef', auto_deref => 1 );
has data => ( is => 'rw', isa => 'HashRef' );

sub BUILD {
  my $this = shift;
  if (my $args = shift) {
    if (my $data = $args->{data}) {
      for my $key(keys(%{$data})) {
        $this->{$key} = $data->{$key}; 
      }
    }
  }
}

sub AUTOLOAD {
  my $this = shift;
  my $key = $1 if $AUTOLOAD =~ /(\w+)$/;;
  return $this->{$key};
}

sub delimited {
  my $this = shift;
  return join($this->delimiter, map { 
      if (my $method = $_->{name} ) {
        $this->$method->value;
      }
    } $this->fields);
}

1;
