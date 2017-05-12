package Data::Maker::Field::Password;
use Data::Maker::Field::Format;
use Moose;
with 'Data::Maker::Field';

our $VERSION = '0.20';

has length => ( is => 'rw', isa => 'Num', default => 8);
has numbers => ( is => 'rw', isa => 'Bool', default => 1);

sub generate_value {
  my ($this, $maker) = @_;
  my $atom = $this->numbers ? '\w' : '\l';
  return Data::Maker::Field::Format->new(
    name => '_dmfpassword',
    format => $atom x $this->length
  )->generate->value;
}

1;
